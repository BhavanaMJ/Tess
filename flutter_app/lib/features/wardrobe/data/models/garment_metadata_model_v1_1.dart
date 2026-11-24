import 'dart:convert';
import '../../domain/entities/garment_metadata_v1_1.dart';

class MetadataValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final GarmentMetadataV1_1? entity;

  const MetadataValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.entity,
  });
}

// ignore: camel_case_types
class GarmentMetadataModelV1_1 {
  static const List<String> validCategories = CategoryNormalization.canonicalCategories;

  static MetadataValidationResult validateJsonString(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const MetadataValidationResult(
        isValid: false,
        errors: ['Metadata JSON is empty. Please paste your garment JSON.'],
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      return MetadataValidationResult(
        isValid: false,
        errors: ['Your metadata JSON is invalid. Please correct the highlighted issue: $e'],
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return const MetadataValidationResult(
        isValid: false,
        errors: ['Expected a JSON object representing garment metadata.'],
      );
    }

    return validateJsonMap(decoded);
  }

  static MetadataValidationResult validateJsonMap(Map<String, dynamic> map) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. schema_version check
    final version = map['schema_version']?.toString();
    if (version != '1.1') {
      errors.add("This metadata version is not supported. Expected '1.1', found '${version ?? 'missing'}'.");
    }

    // 2. record_type check
    final recordType = map['record_type']?.toString();
    if (recordType != 'garment') {
      errors.add("Invalid record_type '${recordType ?? 'missing'}'. Expected 'garment'.");
    }

    // 3. identity check
    final identityMap = (map['identity'] as Map<String, dynamic>?) ?? {};
    final garmentName = identityMap['garment_name']?.toString().trim();
    if (garmentName == null || garmentName.isEmpty) {
      errors.add('Please provide a garment name.');
    }

    final category = identityMap['category']?.toString();
    final customCategory = identityMap['custom_category']?.toString().trim();
    if (category == null || category.trim().isEmpty) {
      errors.add('Select a supported garment category.');
    } else {
      final normalized = CategoryNormalization.normalize(category);
      if (normalized == null && (customCategory == null || customCategory.isEmpty)) {
        errors.add(
          "Unsupported garment category: '${category.trim()}'. "
          "Select a supported garment category. "
          "Supported categories are Tops, Bottoms, Ethnic Wear, Dresses, Outerwear, Activewear, Innerwear, Sleepwear, Footwear and Accessories."
        );
      } else if (normalized != null && normalized != category.trim()) {
        warnings.add("Category '${category.trim()}' was automatically mapped to canonical category '$normalized'.");
      }
    }

    // Parse entity if valid
    GarmentMetadataV1_1? entity;
    if (errors.isEmpty) {
      try {
        entity = fromJson(map);
      } catch (e) {
        errors.add('Failed to parse metadata fields: $e');
      }
    }

    return MetadataValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      entity: entity,
    );
  }

  static GarmentMetadataV1_1 fromJson(Map<String, dynamic> json) {
    final identity = _parseIdentity(json['identity'] as Map<String, dynamic>?);
    final appearance = _parseAppearance(json['appearance'] as Map<String, dynamic>?);
    final construction = _parseConstruction(json['construction'] as Map<String, dynamic>?);
    final material = _parseMaterial(json['material'] as Map<String, dynamic>?);
    final sizing = _parseSizing(json['sizing'] as Map<String, dynamic>?);
    final usage = _parseUsage(json['usage'] as Map<String, dynamic>?);
    final purchase = _parsePurchase(json['purchase'] as Map<String, dynamic>?);
    final care = _parseCare(json['care'] as Map<String, dynamic>?);
    final location = _parseLocation(json['physical_location'] as Map<String, dynamic>?);
    final aiMeta = _parseAiMetadata(json['ai_metadata'] as Map<String, dynamic>?);
    final visual = _parseVisualAssets(json['visual_assets'] as Map<String, dynamic>?);

    final notes = _parseStringList(json['notes']);

    return GarmentMetadataV1_1(
      schemaVersion: json['schema_version']?.toString() ?? '1.1',
      recordType: json['record_type']?.toString() ?? 'garment',
      identity: identity,
      appearance: appearance,
      construction: construction,
      material: material,
      sizing: sizing,
      usage: usage,
      purchase: purchase,
      care: care,
      physicalLocation: location,
      categorySpecific: (json['category_specific'] as Map<String, dynamic>?) ?? {},
      aiMetadata: aiMeta,
      visualAssets: visual,
      notes: notes,
    );
  }

  static Map<String, dynamic> toJson(GarmentMetadataV1_1 entity) {
    return {
      'schema_version': entity.schemaVersion,
      'record_type': entity.recordType,
      'identity': {
        'garment_name': entity.identity.garmentName,
        'category': entity.identity.category,
        'subcategory': entity.identity.subcategory,
        'garment_type': entity.identity.garmentType,
        'description': entity.identity.description,
        'gender_section': entity.identity.genderSection,
        'custom_category': entity.identity.customCategory,
      },
      'appearance': {
        'primary_colour': entity.appearance.primaryColour,
        'secondary_colours': entity.appearance.secondaryColours,
        'accent_colours': entity.appearance.accentColours,
        'colour_family': entity.appearance.colourFamily,
        'colour_temperature': entity.appearance.colourTemperature,
        'colour_distribution': entity.appearance.colourDistribution,
        'pattern': entity.appearance.pattern,
        'pattern_scale': entity.appearance.patternScale,
        'pattern_density': entity.appearance.patternDensity,
        'pattern_placement': entity.appearance.patternPlacement,
        'print_technique': entity.appearance.printTechnique,
        'visual_texture': entity.appearance.visualTexture,
        'surface_finish': entity.appearance.surfaceFinish,
      },
      'construction': {
        'neckline': entity.construction.neckline,
        'collar_type': entity.construction.collarType,
        'sleeve_length': entity.construction.sleeveLength,
        'sleeve_style': entity.construction.sleeveStyle,
        'sleeve_finish': entity.construction.sleeveFinish,
        'shoulder_style': entity.construction.shoulderStyle,
        'silhouette': entity.construction.silhouette,
        'fit': entity.construction.fit,
        'garment_length': entity.construction.garmentLength,
        'hemline': entity.construction.hemline,
        'waist_design': entity.construction.waistDesign,
        'closure_type': entity.construction.closureType,
        'closure_position': entity.construction.closurePosition,
        'pocket_details': entity.construction.pocketDetails,
        'lining': entity.construction.lining,
        'embroidery': entity.construction.embroidery,
        'embellishments': entity.construction.embellishments,
        'slit_details': entity.construction.slitDetails,
        'border_details': entity.construction.borderDetails,
        'decorative_details': entity.construction.decorativeDetails,
        'stitching_details': entity.construction.stitchingDetails,
        'back_design': entity.construction.backDesign,
      },
      'material': {
        'fabric_appearance': entity.material.fabricAppearance,
        'primary_material': entity.material.primaryMaterial,
        'secondary_material': entity.material.secondaryMaterial,
        'fabric_composition': entity.material.fabricComposition,
        'weave_type': entity.material.weaveType,
        'fabric_weight': entity.material.fabricWeight,
        'stretch': entity.material.stretch,
        'transparency': entity.material.transparency,
        'thickness': entity.material.thickness,
        'drape': entity.material.drape,
        'texture': entity.material.texture,
        'surface_finish': entity.material.surfaceFinish,
      },
      'sizing': {
        'labelled_size': entity.sizing.labelledSize,
        'size_system': entity.sizing.sizeSystem,
        'fit_type': entity.sizing.fitType,
        'measurements': {
          'chest': entity.sizing.measurements.chest,
          'waist': entity.sizing.measurements.waist,
          'hip': entity.sizing.measurements.hip,
          'shoulder_width': entity.sizing.measurements.shoulderWidth,
          'sleeve_length': entity.sizing.measurements.sleeveLength,
          'garment_length': entity.sizing.measurements.garmentLength,
          'inseam': entity.sizing.measurements.inseam,
          'outseam': entity.sizing.measurements.outseam,
        },
        'alteration_details': entity.sizing.alterationDetails,
      },
      'usage': {
        'occasions': entity.usage.occasions,
        'seasons': entity.usage.seasons,
        'weather_suitability': entity.usage.weatherSuitability,
        'dress_code': entity.usage.dressCode,
        'style_aesthetic': entity.usage.styleAesthetic,
        'formality_level': entity.usage.formalityLevel,
        'comfort_rating': entity.usage.comfortRating,
        'activity_suitability': entity.usage.activitySuitability,
        'compatible_accessories': entity.usage.compatibleAccessories,
      },
      'purchase': {
        'brand': entity.purchase.brand,
        'product_name': entity.purchase.productName,
        'purchase_date': entity.purchase.purchaseDate?.toString(),
        'purchase_price': entity.purchase.purchasePrice,
        'purchase_currency': entity.purchase.purchaseCurrency,
        'purchase_source': entity.purchase.purchaseSource,
        'store_name': entity.purchase.storeName,
        'product_url': entity.purchase.productUrl,
        'invoice_reference': entity.purchase.invoiceReference,
        'ownership_status': entity.purchase.ownershipStatus,
      },
      'care': {
        'washing_method': entity.care.washingMethod,
        'washing_temperature': entity.care.washingTemperature,
        'bleach_allowed': entity.care.bleachAllowed,
        'ironing_temperature': entity.care.ironingTemperature,
        'drying_method': entity.care.dryingMethod,
        'dry_cleaning': entity.care.dryCleaning,
        'care_label_instructions': entity.care.careLabelInstructions,
        'care_precautions': entity.care.carePrecautions,
      },
      'physical_location': {
        'storage_location': entity.physicalLocation.storageLocation,
        'storage_section': entity.physicalLocation.storageSection,
        'shelf': entity.physicalLocation.shelf,
        'drawer': entity.physicalLocation.drawer,
        'hanger_section': entity.physicalLocation.hangerSection,
        'storage_container': entity.physicalLocation.storageContainer,
        'location_notes': entity.physicalLocation.locationNotes,
      },
      'category_specific': entity.categorySpecific,
      'ai_metadata': {
        'detection_source': entity.aiMetadata.detectionSource,
        'vision_provider': entity.aiMetadata.visionProvider,
        'image_generation_provider': entity.aiMetadata.imageGenerationProvider,
        'model_name': entity.aiMetadata.modelName,
        'processing_timestamp': entity.aiMetadata.processingTimestamp,
        'schema_version': entity.aiMetadata.schemaVersion,
        'attribute_confidence': entity.aiMetadata.attributeConfidence,
        'verification_status': entity.aiMetadata.verificationStatus,
        'user_verified_fields': entity.aiMetadata.userVerifiedFields,
        'user_corrected_fields': entity.aiMetadata.userCorrectedFields,
        'uncertain_fields': entity.aiMetadata.uncertainFields,
        'unknown_fields': entity.aiMetadata.unknownFields,
      },
      'visual_assets': {
        'original_image_description': entity.visualAssets.originalImageDescription,
        'catalogue_image_description': entity.visualAssets.catalogueImageDescription,
        'catalogue_image_generated': entity.visualAssets.catalogueImageGenerated,
        'original_image_preserved': entity.visualAssets.originalImagePreserved,
      },
      'notes': entity.notes,
    };
  }

  static IdentitySection _parseIdentity(Map<String, dynamic>? m) {
    if (m == null) return const IdentitySection();
    final rawCat = m['category']?.toString();
    final normalizedCat = CategoryNormalization.normalize(rawCat) ?? rawCat?.trim();
    return IdentitySection(
      garmentName: m['garment_name']?.toString().trim(),
      category: normalizedCat,
      subcategory: m['subcategory']?.toString(),
      garmentType: m['garment_type']?.toString(),
      description: m['description']?.toString(),
      genderSection: m['gender_section']?.toString(),
      customCategory: m['custom_category']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      return trimmed.contains(',')
          ? trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : [trimmed];
    }
    return [value.toString()];
  }

  static AppearanceSection _parseAppearance(Map<String, dynamic>? m) {
    if (m == null) return const AppearanceSection();
    return AppearanceSection(
      primaryColour: m['primary_colour']?.toString(),
      secondaryColours: _parseStringList(m['secondary_colours']),
      accentColours: _parseStringList(m['accent_colours']),
      colourFamily: m['colour_family']?.toString(),
      colourTemperature: m['colour_temperature']?.toString(),
      colourDistribution: m['colour_distribution']?.toString(),
      pattern: m['pattern']?.toString(),
      patternScale: m['pattern_scale']?.toString(),
      patternDensity: m['pattern_density']?.toString(),
      patternPlacement: m['pattern_placement']?.toString(),
      printTechnique: m['print_technique']?.toString(),
      visualTexture: m['visual_texture']?.toString(),
      surfaceFinish: m['surface_finish']?.toString(),
    );
  }

  static ConstructionSection _parseConstruction(Map<String, dynamic>? m) {
    if (m == null) return const ConstructionSection();
    return ConstructionSection(
      neckline: m['neckline']?.toString(),
      collarType: m['collar_type']?.toString(),
      sleeveLength: m['sleeve_length']?.toString(),
      sleeveStyle: m['sleeve_style']?.toString(),
      sleeveFinish: m['sleeve_finish']?.toString(),
      shoulderStyle: m['shoulder_style']?.toString(),
      silhouette: m['silhouette']?.toString(),
      fit: m['fit']?.toString(),
      garmentLength: m['garment_length']?.toString(),
      hemline: m['hemline']?.toString(),
      waistDesign: m['waist_design']?.toString(),
      closureType: m['closure_type']?.toString(),
      closurePosition: m['closure_position']?.toString(),
      pocketDetails: _parseStringList(m['pocket_details']),
      lining: m['lining']?.toString(),
      embroidery: m['embroidery']?.toString(),
      embellishments: _parseStringList(m['embellishments']),
      slitDetails: m['slit_details']?.toString(),
      borderDetails: m['border_details']?.toString(),
      decorativeDetails: _parseStringList(m['decorative_details']),
      stitchingDetails: m['stitching_details']?.toString(),
      backDesign: m['back_design']?.toString(),
    );
  }

  static MaterialSection _parseMaterial(Map<String, dynamic>? m) {
    if (m == null) return const MaterialSection();
    return MaterialSection(
      fabricAppearance: m['fabric_appearance']?.toString(),
      primaryMaterial: m['primary_material']?.toString(),
      secondaryMaterial: m['secondary_material']?.toString(),
      fabricComposition: m['fabric_composition']?.toString(),
      weaveType: m['weave_type']?.toString(),
      fabricWeight: m['fabric_weight']?.toString(),
      stretch: m['stretch']?.toString(),
      transparency: m['transparency']?.toString(),
      thickness: m['thickness']?.toString(),
      drape: m['drape']?.toString(),
      texture: m['texture']?.toString(),
      surfaceFinish: m['surface_finish']?.toString(),
    );
  }

  static SizingSection _parseSizing(Map<String, dynamic>? m) {
    if (m == null) return const SizingSection();
    final measMap = (m['measurements'] as Map<String, dynamic>?) ?? {};
    return SizingSection(
      labelledSize: m['labelled_size']?.toString(),
      sizeSystem: m['size_system']?.toString(),
      fitType: m['fit_type']?.toString(),
      measurements: MeasurementsSubSection(
        chest: measMap['chest'],
        waist: measMap['waist'],
        hip: measMap['hip'],
        shoulderWidth: measMap['shoulder_width'],
        sleeveLength: measMap['sleeve_length'],
        garmentLength: measMap['garment_length'],
        inseam: measMap['inseam'],
        outseam: measMap['outseam'],
      ),
      alterationDetails: m['alteration_details']?.toString(),
    );
  }

  static UsageSection _parseUsage(Map<String, dynamic>? m) {
    if (m == null) return const UsageSection();
    return UsageSection(
      occasions: _parseStringList(m['occasions']),
      seasons: _parseStringList(m['seasons']),
      weatherSuitability: _parseStringList(m['weather_suitability']),
      dressCode: m['dress_code']?.toString(),
      styleAesthetic: _parseStringList(m['style_aesthetic']),
      formalityLevel: m['formality_level']?.toString(),
      comfortRating: m['comfort_rating'],
      activitySuitability: _parseStringList(m['activity_suitability']),
      compatibleAccessories: _parseStringList(m['compatible_accessories']),
    );
  }

  static PurchaseSection _parsePurchase(Map<String, dynamic>? m) {
    if (m == null) return const PurchaseSection();
    return PurchaseSection(
      brand: m['brand']?.toString(),
      productName: m['product_name']?.toString(),
      purchaseDate: m['purchase_date'],
      purchasePrice: (m['purchase_price'] as num?)?.toDouble(),
      purchaseCurrency: m['purchase_currency']?.toString() ?? 'INR',
      purchaseSource: m['purchase_source']?.toString(),
      storeName: m['store_name']?.toString(),
      productUrl: m['product_url']?.toString(),
      invoiceReference: m['invoice_reference']?.toString(),
      ownershipStatus: m['ownership_status']?.toString(),
    );
  }

  static CareSection _parseCare(Map<String, dynamic>? m) {
    if (m == null) return const CareSection();
    return CareSection(
      washingMethod: m['washing_method']?.toString(),
      washingTemperature: m['washing_temperature']?.toString(),
      bleachAllowed: m['bleach_allowed'] as bool?,
      ironingTemperature: m['ironing_temperature']?.toString(),
      dryingMethod: m['drying_method']?.toString(),
      dryCleaning: m['dry_cleaning'] as bool?,
      careLabelInstructions: m['care_label_instructions']?.toString(),
      carePrecautions: _parseStringList(m['care_precautions']),
    );
  }

  static PhysicalLocationSection _parseLocation(Map<String, dynamic>? m) {
    if (m == null) return const PhysicalLocationSection();
    return PhysicalLocationSection(
      storageLocation: m['storage_location']?.toString(),
      storageSection: m['storage_section']?.toString(),
      shelf: m['shelf']?.toString(),
      drawer: m['drawer']?.toString(),
      hangerSection: m['hanger_section']?.toString(),
      storageContainer: m['storage_container']?.toString(),
      locationNotes: m['location_notes']?.toString(),
    );
  }

  static AiMetadataSection _parseAiMetadata(Map<String, dynamic>? m) {
    if (m == null) return const AiMetadataSection();
    return AiMetadataSection(
      detectionSource: m['detection_source']?.toString() ?? 'user_uploaded_image',
      visionProvider: m['vision_provider']?.toString(),
      imageGenerationProvider: m['image_generation_provider']?.toString(),
      modelName: m['model_name']?.toString(),
      processingTimestamp: m['processing_timestamp']?.toString(),
      schemaVersion: m['schema_version']?.toString() ?? '1.1',
      attributeConfidence: (m['attribute_confidence'] as Map<String, dynamic>?) ?? {},
      verificationStatus: m['verification_status']?.toString() ?? 'pending_user_review',
      userVerifiedFields: _parseStringList(m['user_verified_fields']),
      userCorrectedFields: _parseStringList(m['user_corrected_fields']),
      uncertainFields: _parseStringList(m['uncertain_fields']),
      unknownFields: _parseStringList(m['unknown_fields']),
    );
  }

  static VisualAssetsSection _parseVisualAssets(Map<String, dynamic>? m) {
    if (m == null) return const VisualAssetsSection();
    return VisualAssetsSection(
      originalImageDescription: m['original_image_description']?.toString(),
      catalogueImageDescription: m['catalogue_image_description']?.toString(),
      catalogueImageGenerated: m['catalogue_image_generated'] as bool? ?? false,
      originalImagePreserved: m['original_image_preserved'] as bool? ?? true,
    );
  }
}
