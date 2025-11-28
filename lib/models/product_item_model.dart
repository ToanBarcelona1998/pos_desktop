class ProductItemModel {
  List<Data>? data;
  Links? links;
  Meta? meta;

  ProductItemModel({this.data, this.links, this.meta});

  ProductItemModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
    links = json['links'] != null ? Links.fromJson(json['links']) : null;
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (links != null) {
      data['links'] = links!.toJson();
    }
    if (meta != null) {
      data['meta'] = meta!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? name;
  int? businessId;
  String? type;
  String? subUnitIds;
  int? enableStock;
  String? alertQuantity;
  String? sku;
  String? barcodeType;
  String? expiryPeriod;
  String? expiryPeriodType;
  int? enableSrNo;
  String? weight;
  String? productCustomField1;
  String? productCustomField2;
  String? productCustomField3;
  String? productCustomField4;
  String? image;
  String? woocommerceMediaId;
  String? productDescription;
  int? createdBy;
  String? warrantyId;
  int? isInactive;
  String? repairModelId;
  int? notForSelling;
  String? ecomShippingClassId;
  int? ecomActiveInStore;
  int? woocommerceProductId;
  int? woocommerceDisableSync;
  String? imageUrl;
  List<ProductVariations>? productVariations;
  Brand? brand;
  Unit? unit;
  Category? category;
  Category? subCategory;
  ProductTax? productTax;
  List<ProductLocations>? productLocations;

  Data(
      {this.id,
        this.name,
        this.businessId,
        this.type,
        this.subUnitIds,
        this.enableStock,
        this.alertQuantity,
        this.sku,
        this.barcodeType,
        this.expiryPeriod,
        this.expiryPeriodType,
        this.enableSrNo,
        this.weight,
        this.productCustomField1,
        this.productCustomField2,
        this.productCustomField3,
        this.productCustomField4,
        this.image,
        this.woocommerceMediaId,
        this.productDescription,
        this.createdBy,
        this.warrantyId,
        this.isInactive,
        this.repairModelId,
        this.notForSelling,
        this.ecomShippingClassId,
        this.ecomActiveInStore,
        this.woocommerceProductId,
        this.woocommerceDisableSync,
        this.imageUrl,
        this.productVariations,
        this.brand,
        this.unit,
        this.category,
        this.subCategory,
        this.productTax,
        this.productLocations});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    businessId = json['business_id'];
    type = json['type'];
    subUnitIds = json['sub_unit_ids'];
    enableStock = json['enable_stock'];
    alertQuantity = json['alert_quantity'];
    sku = json['sku'];
    barcodeType = json['barcode_type'];
    expiryPeriod = json['expiry_period'];
    expiryPeriodType = json['expiry_period_type'];
    enableSrNo = json['enable_sr_no'];
    weight = json['weight'];
    productCustomField1 = json['product_custom_field1'];
    productCustomField2 = json['product_custom_field2'];
    productCustomField3 = json['product_custom_field3'];
    productCustomField4 = json['product_custom_field4'];
    image = json['image'];
    woocommerceMediaId = json['woocommerce_media_id'];
    productDescription = json['product_description'];
    createdBy = json['created_by'];
    warrantyId = json['warranty_id'];
    isInactive = json['is_inactive'];
    repairModelId = json['repair_model_id'];
    notForSelling = json['not_for_selling'];
    ecomShippingClassId = json['ecom_shipping_class_id'];
    ecomActiveInStore = json['ecom_active_in_store'];
    woocommerceProductId = json['woocommerce_product_id'];
    woocommerceDisableSync = json['woocommerce_disable_sync'];
    imageUrl = json['image_url'];
    if (json['product_variations'] != null) {
      productVariations = <ProductVariations>[];
      json['product_variations'].forEach((v) {
        productVariations!.add(ProductVariations.fromJson(v));
      });
    }
    brand = json['brand'] != null ? Brand.fromJson(json['brand']) : null;
    unit = json['unit'] != null ? Unit.fromJson(json['unit']) : null;
    category = json['category'] != null
        ? Category.fromJson(json['category'])
        : null;
    subCategory = json['sub_category'] != null
        ? Category.fromJson(json['sub_category'])
        : null;
    productTax = json['product_tax'] != null
        ? ProductTax.fromJson(json['product_tax'])
        : null;
    if (json['product_locations'] != null) {
      productLocations = <ProductLocations>[];
      json['product_locations'].forEach((v) {
        productLocations!.add(ProductLocations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['business_id'] = businessId;
    data['type'] = type;
    data['sub_unit_ids'] = subUnitIds;
    data['enable_stock'] = enableStock;
    data['alert_quantity'] = alertQuantity;
    data['sku'] = sku;
    data['barcode_type'] = barcodeType;
    data['expiry_period'] = expiryPeriod;
    data['expiry_period_type'] = expiryPeriodType;
    data['enable_sr_no'] = enableSrNo;
    data['weight'] = weight;
    data['product_custom_field1'] = productCustomField1;
    data['product_custom_field2'] = productCustomField2;
    data['product_custom_field3'] = productCustomField3;
    data['product_custom_field4'] = productCustomField4;
    data['image'] = image;
    data['woocommerce_media_id'] = woocommerceMediaId;
    data['product_description'] = productDescription;
    data['created_by'] = createdBy;
    data['warranty_id'] = warrantyId;
    data['is_inactive'] = isInactive;
    data['repair_model_id'] = repairModelId;
    data['not_for_selling'] = notForSelling;
    data['ecom_shipping_class_id'] = ecomShippingClassId;
    data['ecom_active_in_store'] = ecomActiveInStore;
    data['woocommerce_product_id'] = woocommerceProductId;
    data['woocommerce_disable_sync'] = woocommerceDisableSync;
    data['image_url'] = imageUrl;
    if (productVariations != null) {
      data['product_variations'] =
          productVariations!.map((v) => v.toJson()).toList();
    }
    if (brand != null) {
      data['brand'] = brand!.toJson();
    }
    if (unit != null) {
      data['unit'] = unit!.toJson();
    }
    if (category != null) {
      data['category'] = category!.toJson();
    }
    if (subCategory != null) {
      data['sub_category'] = subCategory!.toJson();
    }
    if (productTax != null) {
      data['product_tax'] = productTax!.toJson();
    }
    if (productLocations != null) {
      data['product_locations'] =
          productLocations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductVariations {
  int? id;
  String? variationTemplateId;
  String? name;
  int? productId;
  int? isDummy;
  String? createdAt;
  String? updatedAt;
  List<Variations>? variations;

  ProductVariations(
      {this.id,
        this.variationTemplateId,
        this.name,
        this.productId,
        this.isDummy,
        this.createdAt,
        this.updatedAt,
        this.variations});

  ProductVariations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    variationTemplateId = json['variation_template_id'];
    name = json['name'];
    productId = json['product_id'];
    isDummy = json['is_dummy'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['variations'] != null) {
      variations = <Variations>[];
      json['variations'].forEach((v) {
        variations!.add(Variations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['variation_template_id'] = variationTemplateId;
    data['name'] = name;
    data['product_id'] = productId;
    data['is_dummy'] = isDummy;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (variations != null) {
      data['variations'] = variations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Variations {
  int? id;
  String? name;
  int? productId;
  String? subSku;
  int? productVariationId;
  String? woocommerceVariationId;
  String? variationValueId;
  String? defaultPurchasePrice;
  String? dppIncTax;
  String? profitPercent;
  String? defaultSellPrice;
  String? sellPriceIncTax;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  dynamic comboVariations;
  List<VariationLocationDetails>? variationLocationDetails;
  List<Media>? media;
  List<Discounts>? discounts;
  List<SellingPriceGroup>? sellingPriceGroup;

  Variations(
      {this.id,
        this.name,
        this.productId,
        this.subSku,
        this.productVariationId,
        this.woocommerceVariationId,
        this.variationValueId,
        this.defaultPurchasePrice,
        this.dppIncTax,
        this.profitPercent,
        this.defaultSellPrice,
        this.sellPriceIncTax,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.comboVariations,
        this.variationLocationDetails,
        this.media,
        this.discounts,
        this.sellingPriceGroup});

  Variations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    productId = json['product_id'];
    subSku = json['sub_sku'];
    productVariationId = json['product_variation_id'];
    woocommerceVariationId = json['woocommerce_variation_id'];
    variationValueId = json['variation_value_id'];
    defaultPurchasePrice = json['default_purchase_price'];
    dppIncTax = json['dpp_inc_tax'];
    profitPercent = json['profit_percent'];
    defaultSellPrice = json['default_sell_price'];
    sellPriceIncTax = json['sell_price_inc_tax'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    comboVariations = json['combo_variations'];
    if (json['variation_location_details'] != null) {
      variationLocationDetails = <VariationLocationDetails>[];
      json['variation_location_details'].forEach((v) {
        variationLocationDetails!.add(VariationLocationDetails.fromJson(v));
      });
    }
    if (json['media'] != null) {
      media = <Media>[];
      json['media'].forEach((v) {
        media!.add(Media.fromJson(v));
      });
    }
    if (json['discounts'] != null) {
      discounts = <Discounts>[];
      json['discounts'].forEach((v) {
        discounts!.add(Discounts.fromJson(v));
      });
    }
    if (json['selling_price_group'] != null) {
      sellingPriceGroup = <SellingPriceGroup>[];
      json['selling_price_group'].forEach((v) {
        sellingPriceGroup!.add(SellingPriceGroup.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['product_id'] = productId;
    data['sub_sku'] = subSku;
    data['product_variation_id'] = productVariationId;
    data['woocommerce_variation_id'] = woocommerceVariationId;
    data['variation_value_id'] = variationValueId;
    data['default_purchase_price'] = defaultPurchasePrice;
    data['dpp_inc_tax'] = dppIncTax;
    data['profit_percent'] = profitPercent;
    data['default_sell_price'] = defaultSellPrice;
    data['sell_price_inc_tax'] = sellPriceIncTax;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['combo_variations'] = comboVariations;
    if (variationLocationDetails != null) {
      data['variation_location_details'] =
          variationLocationDetails!.map((v) => v.toJson()).toList();
    }
    if (media != null) {
      data['media'] = media!.map((v) => v.toJson()).toList();
    }
    if (discounts != null) {
      data['discounts'] = discounts!.map((v) => v.toJson()).toList();
    }
    if (sellingPriceGroup != null) {
      data['selling_price_group'] =
          sellingPriceGroup!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VariationLocationDetails {
  int? id;
  int? productId;
  int? productVariationId;
  int? variationId;
  int? locationId;
  String? qtyAvailable;
  String? createdAt;
  String? updatedAt;

  VariationLocationDetails(
      {this.id,
        this.productId,
        this.productVariationId,
        this.variationId,
        this.locationId,
        this.qtyAvailable,
        this.createdAt,
        this.updatedAt});

  VariationLocationDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    productVariationId = json['product_variation_id'];
    variationId = json['variation_id'];
    locationId = json['location_id'];
    qtyAvailable = json['qty_available'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['product_variation_id'] = productVariationId;
    data['variation_id'] = variationId;
    data['location_id'] = locationId;
    data['qty_available'] = qtyAvailable;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Media {
  int? id;
  int? businessId;
  String? fileName;
  String? description;
  int? uploadedBy;
  String? modelType;
  String? woocommerceMediaId;
  int? modelId;
  String? createdAt;
  String? updatedAt;
  String? displayName;
  String? displayUrl;

  Media(
      {this.id,
        this.businessId,
        this.fileName,
        this.description,
        this.uploadedBy,
        this.modelType,
        this.woocommerceMediaId,
        this.modelId,
        this.createdAt,
        this.updatedAt,
        this.displayName,
        this.displayUrl});

  Media.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessId = json['business_id'];
    fileName = json['file_name'];
    description = json['description'];
    uploadedBy = json['uploaded_by'];
    modelType = json['model_type'];
    woocommerceMediaId = json['woocommerce_media_id'];
    modelId = json['model_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    displayName = json['display_name'];
    displayUrl = json['display_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_id'] = businessId;
    data['file_name'] = fileName;
    data['description'] = description;
    data['uploaded_by'] = uploadedBy;
    data['model_type'] = modelType;
    data['woocommerce_media_id'] = woocommerceMediaId;
    data['model_id'] = modelId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['display_name'] = displayName;
    data['display_url'] = displayUrl;
    return data;
  }
}

class Discounts {
  int? id;
  String? name;
  int? businessId;
  String? brandId;
  String? categoryId;
  int? locationId;
  int? priority;
  String? discountType;
  String? discountAmount;
  String? startsAt;
  String? endsAt;
  int? isActive;
  String? spg;
  int? applicableInCg;
  String? createdAt;
  String? updatedAt;
  String? formatedStartsAt;
  String? formatedEndsAt;

  Discounts(
      {this.id,
        this.name,
        this.businessId,
        this.brandId,
        this.categoryId,
        this.locationId,
        this.priority,
        this.discountType,
        this.discountAmount,
        this.startsAt,
        this.endsAt,
        this.isActive,
        this.spg,
        this.applicableInCg,
        this.createdAt,
        this.updatedAt,
        this.formatedStartsAt,
        this.formatedEndsAt});

  Discounts.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    businessId = json['business_id'];
    brandId = json['brand_id'];
    categoryId = json['category_id'];
    locationId = json['location_id'];
    priority = json['priority'];
    discountType = json['discount_type'];
    discountAmount = json['discount_amount'];
    startsAt = json['starts_at'];
    endsAt = json['ends_at'];
    isActive = json['is_active'];
    spg = json['spg'];
    applicableInCg = json['applicable_in_cg'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    formatedStartsAt = json['formated_starts_at'];
    formatedEndsAt = json['formated_ends_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['business_id'] = businessId;
    data['brand_id'] = brandId;
    data['category_id'] = categoryId;
    data['location_id'] = locationId;
    data['priority'] = priority;
    data['discount_type'] = discountType;
    data['discount_amount'] = discountAmount;
    data['starts_at'] = startsAt;
    data['ends_at'] = endsAt;
    data['is_active'] = isActive;
    data['spg'] = spg;
    data['applicable_in_cg'] = applicableInCg;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['formated_starts_at'] = formatedStartsAt;
    data['formated_ends_at'] = formatedEndsAt;
    return data;
  }
}

class SellingPriceGroup {
  int? id;
  int? variationId;
  int? priceGroupId;
  String? priceIncTax;
  String? createdAt;
  String? updatedAt;

  SellingPriceGroup(
      {this.id,
        this.variationId,
        this.priceGroupId,
        this.priceIncTax,
        this.createdAt,
        this.updatedAt});

  SellingPriceGroup.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    variationId = json['variation_id'];
    priceGroupId = json['price_group_id'];
    priceIncTax = json['price_inc_tax'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['variation_id'] = variationId;
    data['price_group_id'] = priceGroupId;
    data['price_inc_tax'] = priceIncTax;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Brand {
  int? id;
  int? businessId;
  String? name;
  String? description;
  int? createdBy;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;

  Brand(
      {this.id,
        this.businessId,
        this.name,
        this.description,
        this.createdBy,
        this.deletedAt,
        this.createdAt,
        this.updatedAt});

  Brand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessId = json['business_id'];
    name = json['name'];
    description = json['description'];
    createdBy = json['created_by'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_id'] = businessId;
    data['name'] = name;
    data['description'] = description;
    data['created_by'] = createdBy;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Unit {
  int? id;
  int? businessId;
  String? actualName;
  String? shortName;
  int? allowDecimal;
  String? baseUnitId;
  String? baseUnitMultiplier;
  int? createdBy;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;

  Unit(
      {this.id,
        this.businessId,
        this.actualName,
        this.shortName,
        this.allowDecimal,
        this.baseUnitId,
        this.baseUnitMultiplier,
        this.createdBy,
        this.deletedAt,
        this.createdAt,
        this.updatedAt});

  Unit.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessId = json['business_id'];
    actualName = json['actual_name'];
    shortName = json['short_name'];
    allowDecimal = json['allow_decimal'];
    baseUnitId = json['base_unit_id'];
    baseUnitMultiplier = json['base_unit_multiplier'];
    createdBy = json['created_by'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_id'] = businessId;
    data['actual_name'] = actualName;
    data['short_name'] = shortName;
    data['allow_decimal'] = allowDecimal;
    data['base_unit_id'] = baseUnitId;
    data['base_unit_multiplier'] = baseUnitMultiplier;
    data['created_by'] = createdBy;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Category {
  int? id;
  String? name;
  int? businessId;
  String? shortCode;
  int? parentId;
  int? createdBy;
  String? categoryType;
  String? description;
  String? slug;
  String? woocommerceCatId;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;

  Category(
      {this.id,
        this.name,
        this.businessId,
        this.shortCode,
        this.parentId,
        this.createdBy,
        this.categoryType,
        this.description,
        this.slug,
        this.woocommerceCatId,
        this.deletedAt,
        this.createdAt,
        this.updatedAt});

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    businessId = json['business_id'];
    shortCode = json['short_code'];
    parentId = json['parent_id'];
    createdBy = json['created_by'];
    categoryType = json['category_type'];
    description = json['description'];
    slug = json['slug'];
    woocommerceCatId = json['woocommerce_cat_id'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['business_id'] = businessId;
    data['short_code'] = shortCode;
    data['parent_id'] = parentId;
    data['created_by'] = createdBy;
    data['category_type'] = categoryType;
    data['description'] = description;
    data['slug'] = slug;
    data['woocommerce_cat_id'] = woocommerceCatId;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ProductTax {
  int? id;
  int? businessId;
  String? name;
  int? amount;
  int? isTaxGroup;
  int? createdBy;
  String? woocommerceTaxRateId;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;

  ProductTax(
      {this.id,
        this.businessId,
        this.name,
        this.amount,
        this.isTaxGroup,
        this.createdBy,
        this.woocommerceTaxRateId,
        this.deletedAt,
        this.createdAt,
        this.updatedAt});

  ProductTax.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessId = json['business_id'];
    name = json['name'];
    amount = json['amount'];
    isTaxGroup = json['is_tax_group'];
    createdBy = json['created_by'];
    woocommerceTaxRateId = json['woocommerce_tax_rate_id'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_id'] = businessId;
    data['name'] = name;
    data['amount'] = amount;
    data['is_tax_group'] = isTaxGroup;
    data['created_by'] = createdBy;
    data['woocommerce_tax_rate_id'] = woocommerceTaxRateId;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ProductLocations {
  int? id;
  int? businessId;
  String? locationId;
  String? name;
  String? landmark;
  String? country;
  String? state;
  String? city;
  String? zipCode;
  int? invoiceSchemeId;
  int? invoiceLayoutId;
  int? sellingPriceGroupId;
  int? printReceiptOnInvoice;
  String? receiptPrinterType;
  String? printerId;
  String? mobile;
  String? alternateNumber;
  String? email;
  String? website;
  List<String>? featuredProducts;
  int? isActive;
  String? defaultPaymentAccounts;
  String? customField1;
  String? customField2;
  String? customField3;
  String? customField4;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;
  Pivot? pivot;

  ProductLocations(
      {this.id,
        this.businessId,
        this.locationId,
        this.name,
        this.landmark,
        this.country,
        this.state,
        this.city,
        this.zipCode,
        this.invoiceSchemeId,
        this.invoiceLayoutId,
        this.sellingPriceGroupId,
        this.printReceiptOnInvoice,
        this.receiptPrinterType,
        this.printerId,
        this.mobile,
        this.alternateNumber,
        this.email,
        this.website,
        this.featuredProducts,
        this.isActive,
        this.defaultPaymentAccounts,
        this.customField1,
        this.customField2,
        this.customField3,
        this.customField4,
        this.deletedAt,
        this.createdAt,
        this.updatedAt,
        this.pivot});

  ProductLocations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    businessId = json['business_id'];
    locationId = json['location_id'];
    name = json['name'];
    landmark = json['landmark'];
    country = json['country'];
    state = json['state'];
    city = json['city'];
    zipCode = json['zip_code'];
    invoiceSchemeId = json['invoice_scheme_id'];
    invoiceLayoutId = json['invoice_layout_id'];
    sellingPriceGroupId = json['selling_price_group_id'];
    printReceiptOnInvoice = json['print_receipt_on_invoice'];
    receiptPrinterType = json['receipt_printer_type'];
    printerId = json['printer_id'];
    mobile = json['mobile'];
    alternateNumber = json['alternate_number'];
    email = json['email'];
    website = json['website'];
    featuredProducts = json['featured_products'];
    isActive = json['is_active'];
    defaultPaymentAccounts = json['default_payment_accounts'];
    customField1 = json['custom_field1'];
    customField2 = json['custom_field2'];
    customField3 = json['custom_field3'];
    customField4 = json['custom_field4'];
    deletedAt = json['deleted_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['business_id'] = businessId;
    data['location_id'] = locationId;
    data['name'] = name;
    data['landmark'] = landmark;
    data['country'] = country;
    data['state'] = state;
    data['city'] = city;
    data['zip_code'] = zipCode;
    data['invoice_scheme_id'] = invoiceSchemeId;
    data['invoice_layout_id'] = invoiceLayoutId;
    data['selling_price_group_id'] = sellingPriceGroupId;
    data['print_receipt_on_invoice'] = printReceiptOnInvoice;
    data['receipt_printer_type'] = receiptPrinterType;
    data['printer_id'] = printerId;
    data['mobile'] = mobile;
    data['alternate_number'] = alternateNumber;
    data['email'] = email;
    data['website'] = website;
    data['featured_products'] = featuredProducts;
    data['is_active'] = isActive;
    data['default_payment_accounts'] = defaultPaymentAccounts;
    data['custom_field1'] = customField1;
    data['custom_field2'] = customField2;
    data['custom_field3'] = customField3;
    data['custom_field4'] = customField4;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    return data;
  }
}

class Pivot {
  int? productId;
  int? locationId;

  Pivot({this.productId, this.locationId});

  Pivot.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    locationId = json['location_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId;
    data['location_id'] = locationId;
    return data;
  }
}

class Links {
  String? first;
  String? last;
  String? prev;
  String? next;

  Links({this.first, this.last, this.prev, this.next});

  Links.fromJson(Map<String, dynamic> json) {
    first = json['first'];
    last = json['last'];
    prev = json['prev'];
    next = json['next'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first'] = first;
    data['last'] = last;
    data['prev'] = prev;
    data['next'] = next;
    return data;
  }
}

class Meta {
  int? currentPage;
  int? from;
  String? path;
  int? perPage;
  int? to;
  int? lastPage;

  Meta({this.currentPage, this.from, this.path, this.perPage, this.to,this.lastPage});

  Meta.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    from = json['from'];
    path = json['path'];
    perPage = json['per_page'];
    to = json['to'];
    lastPage = json['last_page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['from'] = from;
    data['path'] = path;
    data['per_page'] = perPage;
    data['to'] = to;
    data['last_page'] = lastPage;
    return data;
  }
}
