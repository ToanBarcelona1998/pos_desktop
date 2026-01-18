import 'package:domain/domain.dart';

import '../../data.dart';
import '../core/exception_handler.dart';
import '../core/exceptions.dart';
import '../data_source/local/cashier_session_local_data_source.dart';
import '../data_source/remote/cashier_session_remote_data_source.dart';
import '../mapper/cashier_session_mapper.dart';

/// Implementation of CashierSessionRepository
class CashierSessionRepositoryImpl implements CashierSessionRepository {
  final CashierSessionRemoteDataSource _remoteDataSource;
  final CashierSessionLocalDataSource _localDataSource;
  final CashierSessionMapper _mapper;
  final SellRepository _sellRepository;

  CashierSessionRepositoryImpl({
    required CashierSessionRemoteDataSource remoteDataSource,
    required CashierSessionLocalDataSource localDataSource,
    CashierSessionMapper? mapper,
    required SellRepository sellRepository,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _mapper = mapper ?? const CashierSessionMapper(),
        _sellRepository = sellRepository;

  @override
  Future<Result<CashierSessionEntity?>> getActiveSession({
    required int userId,
    required int locationId,
  }) async {
    try {
      final localSession = await _localDataSource.getActiveSession(
        userId: userId,
        locationId: locationId,
      );

      if (localSession != null) {
        return Success(_mapper.toEntity(localSession));
      }

      return const Success(null);
    } catch (e) {
      Logger.logE('Error getting active session', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<CashierSessionEntity>> checkIn({
    required int locationId,
    required double amount,
    required int userId,
  }) async {
    try {
      try {
        final remoteSession = await _remoteDataSource.checkIn(
          locationId: locationId,
          amount: amount,
        );
        await _localDataSource.saveSession(remoteSession);
        return Success(_mapper.toEntity(remoteSession));
      } catch (e) {
        Logger.logE('Check-in failed, saving to local', e);

        // If remote fails, create local session
        final localSession = CashierSessionModel(
          userId: userId,
          locationId: locationId,
          openingAmount: amount,
          startTime: DateTime.now(),
          status: 'active',
          isSynced: false,
        );

        await _localDataSource.saveSession(localSession);
        return Success(_mapper.toEntity(localSession));
      }
    } catch (e) {
      Logger.logE('Error in check-in', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<CashierSessionEntity>> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
    required int userId,
    required int locationId,
  }) async {
    Logger.logI('🚪 [CashierSessionRepository] Starting checkout - userId: $userId, locationId: $locationId');
    
    try {
      // Check if local session is already closed (may happen if previous checkout succeeded but update failed)
      final localActiveSession = await _localDataSource.getActiveSession(
        userId: userId,
        locationId: locationId,
      );
      
      if (localActiveSession == null) {
        Logger.logI('⚠️ [CashierSessionRepository] No active local session found - may already be closed');
        // Continue with checkout - server may have active session
      } else if (localActiveSession.status == 'closed' && localActiveSession.isSynced) {
        Logger.logI('✅ [CashierSessionRepository] Local session already closed and synced - checkout may already be completed');
        // Return success with local closed session
        return Success(_mapper.toEntity(localActiveSession));
      }
      
      // Step 1: Sync unsynced sessions first - BẮT BUỘC phải thành công
      Logger.logI('🔄 [CashierSessionRepository] Step 1: Syncing unsynced sessions...');
      final syncSessionsResult = await syncUnsyncedSessions();
      
      // Block checkout if sync sessions fails - keep current state to prevent data loss
      Failure? syncSessionsFailure;
      await syncSessionsResult.fold(
        onSuccess: (_) {
          Logger.logI('✅ [CashierSessionRepository] All unsynced sessions synced successfully');
        },
        onError: (failure) {
          Logger.logE('❌ [CashierSessionRepository] Failed to sync sessions before checkout: ${failure.message}', null);
          syncSessionsFailure = failure;
        },
      );

      // Return error to block checkout if sync sessions failed
      if (syncSessionsFailure != null) {
        Logger.logE('❌ [CashierSessionRepository] Checkout blocked - session sync failed. Keeping current state to prevent data loss.', null);
        return Error(syncSessionsFailure!);
      }

      // Step 2: Sync unsynced sells before checkout - BẮT BUỘC phải thành công
      // This ensures all sales data is synced to server before closing the session
      Logger.logI('🔄 [CashierSessionRepository] Step 2: Syncing unsynced sells before checkout...');
      final syncSellsResult = await _sellRepository.syncSells();
      
      // Block checkout if sync sells fails - keep current state to prevent data loss
      Failure? syncSellsFailure;
      await syncSellsResult.fold(
        onSuccess: (_) {
          Logger.logI('✅ [CashierSessionRepository] All unsynced sells synced successfully before checkout');
        },
        onError: (failure) {
          Logger.logE('❌ [CashierSessionRepository] Failed to sync sells before checkout: ${failure.message}', null);
          syncSellsFailure = failure;
        },
      );

      // Return error to block checkout if sync sells failed
      if (syncSellsFailure != null) {
        Logger.logE('❌ [CashierSessionRepository] Checkout blocked - sell sync failed. Keeping current state to prevent data loss.', null);
        return Error(syncSellsFailure!);
      }

      // Step 3: Try remote check-out - BẮT BUỘC phải thành công
      // Không lưu local nếu remote fail
      Logger.logI('🚪 [CashierSessionRepository] Step 3: Calling remote checkout API...');
      Logger.logI('📊 [CashierSessionRepository] Checkout params - closingAmount: $closingAmount, closingAmountOnStaff: $closingAmountOnStaff, totalCardSlips: $totalCardSlips, totalCheques: $totalCheques');
      
      final remoteSession = await _remoteDataSource.checkOut(
        closingAmount: closingAmount,
        closingAmountOnStaff: closingAmountOnStaff,
        totalCardSlips: totalCardSlips,
        totalCheques: totalCheques,
        closingNote: closingNote,
        denominations: denominations,
      );

      Logger.logI('✅ [CashierSessionRepository] Remote checkout successful - sessionId: ${remoteSession.id}');

      // Step 4: Mark local session as synced (if exists)
      // IMPORTANT: After checkout success, user will logout immediately and user database will be deleted
      // So we only need to mark session as synced, not update all fields
      Logger.logI('💾 [CashierSessionRepository] Step 4: Marking local session as synced...');
      
      try {
        // Try to mark session as synced using remote session id if available
        if (remoteSession.id != null) {
          await _localDataSource.markSessionAsSynced(remoteSession.id!);
          Logger.logI('✅ [CashierSessionRepository] Local session marked as synced - sessionId: ${remoteSession.id}');
        } else {
          // API response doesn't include session id - get active local session and mark as synced
          Logger.logI('⚠️ [CashierSessionRepository] API response doesn\'t include session id - finding active local session');
          final localActiveSession = await _localDataSource.getActiveSession(
            userId: userId,
            locationId: locationId,
          );
          
          if (localActiveSession != null && localActiveSession.id != null) {
            await _localDataSource.markSessionAsSynced(localActiveSession.id!);
            Logger.logI('✅ [CashierSessionRepository] Local session marked as synced - sessionId: ${localActiveSession.id}');
          } else {
            Logger.logI('⚠️ [CashierSessionRepository] No active local session found to mark as synced');
          }
        }
      } catch (localUpdateError, stackTrace) {
        // Local update failed, but checkout was successful on server
        // Log warning but don't fail the checkout (database will be deleted on logout anyway)
        Logger.logE('⚠️ [CashierSessionRepository] Failed to mark local session as synced after successful checkout on server', localUpdateError);
        Logger.logE('⚠️ [CashierSessionRepository] Local update error details: ${localUpdateError.toString()}', localUpdateError);
        Logger.logE('⚠️ [CashierSessionRepository] Stack trace: $stackTrace', localUpdateError);
        // Continue - checkout is successful on server and database will be deleted on logout
      }

      Logger.logI('✅ [CashierSessionRepository] Checkout completed successfully');
      
      // Return remote session entity (or create minimal entity if remote doesn't have id)
      if (remoteSession.id != null) {
        return Success(_mapper.toEntity(remoteSession));
      } else {
        // Create minimal entity from checkout params (API doesn't return session data)
        final minimalSession = CashierSessionModel(
          userId: userId,
          locationId: locationId,
          openingAmount: 0, // Not available from response
          closingAmount: closingAmount,
          closingAmountOnStaff: closingAmountOnStaff,
          totalCardSlips: totalCardSlips,
          totalCheques: totalCheques,
          closingNote: closingNote,
          denominations: denominations,
          status: 'closed',
          isSynced: true,
        );
        return Success(_mapper.toEntity(minimalSession));
      }

    } catch (e, stackTrace) {
      Logger.logE('❌ [CashierSessionRepository] Check-out failed - must retry', e);
      Logger.logE('❌ [CashierSessionRepository] Error details - userId: $userId, locationId: $locationId', e);
      Logger.logE('❌ [CashierSessionRepository] Exception: ${e.toString()}', e);
      Logger.logE('❌ [CashierSessionRepository] Stack trace: $stackTrace', e);
      
      // Log additional details if it's an API error
      if (e is Exception) {
        Logger.logE('❌ [CashierSessionRepository] Exception type: ${e.runtimeType}', e);
      }
      
      // Handle 409 Conflict - session may already be closed on server
      // Mark local session as synced and return success (since checkout is effectively done)
      if (e is ServerException && e.statusCode == 409) {
        Logger.logI('⚠️ [CashierSessionRepository] Received 409 Conflict - session already closed on server');
        
        // Mark local session as synced if exists
        final localActiveSession = await _localDataSource.getActiveSession(
          userId: userId,
          locationId: locationId,
        );
        
        if (localActiveSession != null && localActiveSession.id != null) {
          Logger.logI('✅ [CashierSessionRepository] Marking local session as synced (409 Conflict - checkout already completed on server)');
          try {
            await _localDataSource.markSessionAsSynced(localActiveSession.id!);
            Logger.logI('✅ [CashierSessionRepository] Local session marked as synced - checkout already completed on server');
            
            // Return success - checkout is effectively done on server
            final closedSession = CashierSessionModel(
              id: localActiveSession.id,
              userId: localActiveSession.userId,
              locationId: localActiveSession.locationId,
              openingAmount: localActiveSession.openingAmount,
              closingAmount: closingAmount,
              closingAmountOnStaff: closingAmountOnStaff,
              totalCardSlips: totalCardSlips,
              totalCheques: totalCheques,
              closingNote: closingNote,
              denominations: denominations,
              startTime: localActiveSession.startTime,
              endTime: DateTime.now(),
              status: 'closed',
              isSynced: true,
            );
            
            return Success(_mapper.toEntity(closedSession));
          } catch (updateError) {
            Logger.logE('❌ [CashierSessionRepository] Failed to mark local session as synced after 409 Conflict', updateError);
            // Still return success since checkout is done on server
            return Success(_mapper.toEntity(localActiveSession));
          }
        } else {
          // No local session found - checkout already completed, return success
          Logger.logI('✅ [CashierSessionRepository] No local session found - checkout already completed on server');
          final minimalSession = CashierSessionModel(
            userId: userId,
            locationId: locationId,
            openingAmount: 0,
            closingAmount: closingAmount,
            closingAmountOnStaff: closingAmountOnStaff,
            totalCardSlips: totalCardSlips,
            totalCheques: totalCheques,
            closingNote: closingNote,
            denominations: denominations,
            status: 'closed',
            isSynced: true,
          );
          return Success(_mapper.toEntity(minimalSession));
        }
      }
      
      // Không lưu local khi checkout fail
      // Return error để user phải retry
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncUnsyncedSessions() async {
    try {
      Logger.logI('🔄 [CashierSessionRepository] Checking for unsynced sessions...');
      final unsyncedSessions = await _localDataSource.getUnsyncedSessions();
      
      if (unsyncedSessions.isEmpty) {
        Logger.logI('✅ [CashierSessionRepository] No unsynced sessions found');
        return const Success(null);
      }

      Logger.logI('📋 [CashierSessionRepository] Found ${unsyncedSessions.length} unsynced sessions');

      int successCount = 0;
      int failCount = 0;

      for (final session in unsyncedSessions) {
        try {
          if (session.status == 'active') {
            // Sync check-in
            Logger.logI('🔄 [CashierSessionRepository] Syncing check-in - sessionId: ${session.id}, locationId: ${session.locationId}, amount: ${session.openingAmount}');
            await _remoteDataSource.checkIn(
              locationId: session.locationId,
              amount: session.openingAmount,
            );
            if (session.id != null) {
              await _localDataSource.markSessionAsSynced(session.id!);
              Logger.logI('✅ [CashierSessionRepository] Check-in synced successfully - sessionId: ${session.id}');
              successCount++;
            }
          } else if (session.status == 'closed') {
            // Sync check-out
            Logger.logI('🔄 [CashierSessionRepository] Syncing check-out - sessionId: ${session.id}');
            await _remoteDataSource.checkOut(
              closingAmount: session.closingAmount ?? 0,
              closingAmountOnStaff: session.closingAmountOnStaff ?? 0,
              totalCardSlips: session.totalCardSlips ?? 0,
              totalCheques: session.totalCheques ?? 0,
              closingNote: session.closingNote ?? '',
              denominations: session.denominations ?? {},
            );
            if (session.id != null) {
              await _localDataSource.markSessionAsSynced(session.id!);
              Logger.logI('✅ [CashierSessionRepository] Check-out synced successfully - sessionId: ${session.id}');
              successCount++;
            }
          }
        } catch (e, stackTrace) {
          final sessionType = session.status == 'active' ? 'check-in' : 'check-out';
          Logger.logE('❌ [CashierSessionRepository] Failed to sync $sessionType - sessionId: ${session.id}', e);
          Logger.logE('❌ [CashierSessionRepository] Sync error details: ${e.toString()}', e);
          Logger.logE('❌ [CashierSessionRepository] Stack trace: $stackTrace', e);
          failCount++;
          // Continue with other sessions even if one fails
        }
      }

      // Log summary
      if (failCount == 0) {
        Logger.logI('✅ [CashierSessionRepository] All $successCount sessions synced successfully');
      } else {
        Logger.logI('⚠️ [CashierSessionRepository] Session sync completed - $successCount succeeded, $failCount failed');
      }
      
      return const Success(null);
    } catch (e) {
      Logger.logE('❌ [CashierSessionRepository] Error syncing sessions', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<CashierSessionEntity>> saveSessionLocally({
    required int userId,
    required int locationId,
    required double openingAmount,
    required DateTime startTime,
    bool isSynced = true,
  }) async {
    try {
      final session = CashierSessionModel(
        userId: userId,
        locationId: locationId,
        openingAmount: openingAmount,
        startTime: startTime,
        status: 'active',
        isSynced: isSynced,
      );

      await _localDataSource.saveSession(session);

      // Get the saved session to return with id
      final savedSession = await _localDataSource.getActiveSession(
        userId: userId,
        locationId: locationId,
      );

      if (savedSession == null) {
        return const Error(
            UnknownFailure(message: 'Failed to save session locally'));
      }

      return Success(_mapper.toEntity(savedSession));
    } catch (e) {
      Logger.logE('Error saving session locally', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }
}
