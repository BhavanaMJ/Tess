library;

/// Canonical category normalization system for TESS Smart Capture
class CategoryNormalization {
  static const List<String> canonicalCategories = [
    'Tops',
    'Bottoms',
    'Ethnic Wear',
    'Dresses',
    'Outerwear',
    'Activewear',
    'Innerwear',
    'Sleepwear',
    'Footwear',
    'Accessories',
  ];

  static const Map<String, String> categoryAliases = {
    // Bottoms aliases
    'bottoms': 'Bottoms',
    'bottomwear': 'Bottoms',
    'bottom wear': 'Bottoms',
    'pants': 'Bottoms',
    'pant': 'Bottoms',
    'trousers': 'Bottoms',
    'trouser': 'Bottoms',
    'lowerwear': 'Bottoms',
    // Tops aliases
    'tops': 'Tops',
    'top': 'Tops',
    'topwear': 'Tops',
    'upperwear': 'Tops',
    // Ethnic Wear aliases
    'ethnic wear': 'Ethnic Wear',
    'ethnicwear': 'Ethnic Wear',
    // Dresses aliases
    'dresses': 'Dresses',
    'dress': 'Dresses',
    // Outerwear aliases
    'outerwear': 'Outerwear',
    // Activewear aliases
    'activewear': 'Activewear',
    // Innerwear aliases
    'innerwear': 'Innerwear',
    // Sleepwear aliases
    'sleepwear': 'Sleepwear',
    // Footwear aliases
    'footwear': 'Footwear',
    // Accessories aliases
    'accessories': 'Accessories',
  };

  /// Normalizes any recognized category alias or canonical category to its canonical form.
  /// Matching is case-insensitive and ignores leading/trailing whitespace.
  /// Returns null if the category is not recognized.
  static String? normalize(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (categoryAliases.containsKey(lower)) {
      return categoryAliases[lower];
    }
    for (final canonical in canonicalCategories) {
      if (canonical.toLowerCase() == lower) {
        return canonical;
      }
    }
    return null;
  }
}

/// TESS Garment Metadata Schema Version 1.1 Domain Entity
/// Represents structured interchange contract between ChatGPT and TESS.

class IdentitySection {
  final String? garmentName;
  final String? category;
  final String? subcategory;
  final String? garmentType;
  final String? description;
  final String? genderSection;
  final String? customCategory;

  const IdentitySection({
    this.garmentName,
    this.category,
    this.subcategory,
    this.garmentType,
    this.description,
    this.genderSection,
    this.customCategory,
  });

  IdentitySection copyWith({
    String? garmentName,
    String? category,
    String? subcategory,
    String? garmentType,
    String? description,
    String? genderSection,
    String? customCategory,
  }) {
    return IdentitySection(
      garmentName: garmentName ?? this.garmentName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      garmentType: garmentType ?? this.garmentType,
      description: description ?? this.description,
      genderSection: genderSection ?? this.genderSection,
      customCategory: customCategory ?? this.customCategory,
    );
  }
}

class AppearanceSection {
  final String? primaryColour;
  final List<String> secondaryColours;
  final List<String> accentColours;
  final String? colourFamily;
  final String? colourTemperature;
  final String? colourDistribution;
  final String? pattern;
  final String? patternScale;
  final String? patternDensity;
  final String? patternPlacement;
  final String? printTechnique;
  final String? visualTexture;
  final String? surfaceFinish;

  const AppearanceSection({
    this.primaryColour,
    this.secondaryColours = const [],
    this.accentColours = const [],
    this.colourFamily,
    this.colourTemperature,
    this.colourDistribution,
    this.pattern,
    this.patternScale,
    this.patternDensity,
    this.patternPlacement,
    this.printTechnique,
    this.visualTexture,
    this.surfaceFinish,
  });

  AppearanceSection copyWith({
    String? primaryColour,
    List<String>? secondaryColours,
    List<String>? accentColours,
    String? colourFamily,
    String? colourTemperature,
    String? colourDistribution,
    String? pattern,
    String? patternScale,
    String? patternDensity,
    String? patternPlacement,
    String? printTechnique,
    String? visualTexture,
    String? surfaceFinish,
  }) {
    return AppearanceSection(
      primaryColour: primaryColour ?? this.primaryColour,
      secondaryColours: secondaryColours ?? this.secondaryColours,
      accentColours: accentColours ?? this.accentColours,
      colourFamily: colourFamily ?? this.colourFamily,
      colourTemperature: colourTemperature ?? this.colourTemperature,
      colourDistribution: colourDistribution ?? this.colourDistribution,
      pattern: pattern ?? this.pattern,
      patternScale: patternScale ?? this.patternScale,
      patternDensity: patternDensity ?? this.patternDensity,
      patternPlacement: patternPlacement ?? this.patternPlacement,
      printTechnique: printTechnique ?? this.printTechnique,
      visualTexture: visualTexture ?? this.visualTexture,
      surfaceFinish: surfaceFinish ?? this.surfaceFinish,
    );
  }
}

class ConstructionSection {
  final String? neckline;
  final String? collarType;
  final String? sleeveLength;
  final String? sleeveStyle;
  final String? sleeveFinish;
  final String? shoulderStyle;
  final String? silhouette;
  final String? fit;
  final String? garmentLength;
  final String? hemline;
  final String? waistDesign;
  final String? closureType;
  final String? closurePosition;
  final List<String> pocketDetails;
  final String? lining;
  final String? embroidery;
  final List<String> embellishments;
  final String? slitDetails;
  final String? borderDetails;
  final List<String> decorativeDetails;
  final String? stitchingDetails;
  final String? backDesign;

  const ConstructionSection({
    this.neckline,
    this.collarType,
    this.sleeveLength,
    this.sleeveStyle,
    this.sleeveFinish,
    this.shoulderStyle,
    this.silhouette,
    this.fit,
    this.garmentLength,
    this.hemline,
    this.waistDesign,
    this.closureType,
    this.closurePosition,
    this.pocketDetails = const [],
    this.lining,
    this.embroidery,
    this.embellishments = const [],
    this.slitDetails,
    this.borderDetails,
    this.decorativeDetails = const [],
    this.stitchingDetails,
    this.backDesign,
  });

  ConstructionSection copyWith({
    String? neckline,
    String? collarType,
    String? sleeveLength,
    String? sleeveStyle,
    String? sleeveFinish,
    String? shoulderStyle,
    String? silhouette,
    String? fit,
    String? garmentLength,
    String? hemline,
    String? waistDesign,
    String? closureType,
    String? closurePosition,
    List<String>? pocketDetails,
    String? lining,
    String? embroidery,
    List<String>? embellishments,
    String? slitDetails,
    String? borderDetails,
    List<String>? decorativeDetails,
    String? stitchingDetails,
    String? backDesign,
  }) {
    return ConstructionSection(
      neckline: neckline ?? this.neckline,
      collarType: collarType ?? this.collarType,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      sleeveStyle: sleeveStyle ?? this.sleeveStyle,
      sleeveFinish: sleeveFinish ?? this.sleeveFinish,
      shoulderStyle: shoulderStyle ?? this.shoulderStyle,
      silhouette: silhouette ?? this.silhouette,
      fit: fit ?? this.fit,
      garmentLength: garmentLength ?? this.garmentLength,
      hemline: hemline ?? this.hemline,
      waistDesign: waistDesign ?? this.waistDesign,
      closureType: closureType ?? this.closureType,
      closurePosition: closurePosition ?? this.closurePosition,
      pocketDetails: pocketDetails ?? this.pocketDetails,
      lining: lining ?? this.lining,
      embroidery: embroidery ?? this.embroidery,
      embellishments: embellishments ?? this.embellishments,
      slitDetails: slitDetails ?? this.slitDetails,
      borderDetails: borderDetails ?? this.borderDetails,
      decorativeDetails: decorativeDetails ?? this.decorativeDetails,
      stitchingDetails: stitchingDetails ?? this.stitchingDetails,
      backDesign: backDesign ?? this.backDesign,
    );
  }
}

class MaterialSection {
  final String? fabricAppearance;
  final String? primaryMaterial;
  final String? secondaryMaterial;
  final String? fabricComposition;
  final String? weaveType;
  final String? fabricWeight;
  final String? stretch;
  final String? transparency;
  final String? thickness;
  final String? drape;
  final String? texture;
  final String? surfaceFinish;

  const MaterialSection({
    this.fabricAppearance,
    this.primaryMaterial,
    this.secondaryMaterial,
    this.fabricComposition,
    this.weaveType,
    this.fabricWeight,
    this.stretch,
    this.transparency,
    this.thickness,
    this.drape,
    this.texture,
    this.surfaceFinish,
  });

  MaterialSection copyWith({
    String? fabricAppearance,
    String? primaryMaterial,
    String? secondaryMaterial,
    String? fabricComposition,
    String? weaveType,
    String? fabricWeight,
    String? stretch,
    String? transparency,
    String? thickness,
    String? drape,
    String? texture,
    String? surfaceFinish,
  }) {
    return MaterialSection(
      fabricAppearance: fabricAppearance ?? this.fabricAppearance,
      primaryMaterial: primaryMaterial ?? this.primaryMaterial,
      secondaryMaterial: secondaryMaterial ?? this.secondaryMaterial,
      fabricComposition: fabricComposition ?? this.fabricComposition,
      weaveType: weaveType ?? this.weaveType,
      fabricWeight: fabricWeight ?? this.fabricWeight,
      stretch: stretch ?? this.stretch,
      transparency: transparency ?? this.transparency,
      thickness: thickness ?? this.thickness,
      drape: drape ?? this.drape,
      texture: texture ?? this.texture,
      surfaceFinish: surfaceFinish ?? this.surfaceFinish,
    );
  }
}

class MeasurementsSubSection {
  final dynamic chest;
  final dynamic waist;
  final dynamic hip;
  final dynamic shoulderWidth;
  final dynamic sleeveLength;
  final dynamic garmentLength;
  final dynamic inseam;
  final dynamic outseam;

  const MeasurementsSubSection({
    this.chest,
    this.waist,
    this.hip,
    this.shoulderWidth,
    this.sleeveLength,
    this.garmentLength,
    this.inseam,
    this.outseam,
  });
}

class SizingSection {
  final String? labelledSize;
  final String? sizeSystem;
  final String? fitType;
  final MeasurementsSubSection measurements;
  final String? alterationDetails;

  const SizingSection({
    this.labelledSize,
    this.sizeSystem,
    this.fitType,
    this.measurements = const MeasurementsSubSection(),
    this.alterationDetails,
  });

  SizingSection copyWith({
    String? labelledSize,
    String? sizeSystem,
    String? fitType,
    MeasurementsSubSection? measurements,
    String? alterationDetails,
  }) {
    return SizingSection(
      labelledSize: labelledSize ?? this.labelledSize,
      sizeSystem: sizeSystem ?? this.sizeSystem,
      fitType: fitType ?? this.fitType,
      measurements: measurements ?? this.measurements,
      alterationDetails: alterationDetails ?? this.alterationDetails,
    );
  }
}

class UsageSection {
  final List<String> occasions;
  final List<String> seasons;
  final List<String> weatherSuitability;
  final String? dressCode;
  final List<String> styleAesthetic;
  final String? formalityLevel;
  final dynamic comfortRating;
  final List<String> activitySuitability;
  final List<String> compatibleAccessories;

  const UsageSection({
    this.occasions = const [],
    this.seasons = const [],
    this.weatherSuitability = const [],
    this.dressCode,
    this.styleAesthetic = const [],
    this.formalityLevel,
    this.comfortRating,
    this.activitySuitability = const [],
    this.compatibleAccessories = const [],
  });

  UsageSection copyWith({
    List<String>? occasions,
    List<String>? seasons,
    List<String>? weatherSuitability,
    String? dressCode,
    List<String>? styleAesthetic,
    String? formalityLevel,
    dynamic comfortRating,
    List<String>? activitySuitability,
    List<String>? compatibleAccessories,
  }) {
    return UsageSection(
      occasions: occasions ?? this.occasions,
      seasons: seasons ?? this.seasons,
      weatherSuitability: weatherSuitability ?? this.weatherSuitability,
      dressCode: dressCode ?? this.dressCode,
      styleAesthetic: styleAesthetic ?? this.styleAesthetic,
      formalityLevel: formalityLevel ?? this.formalityLevel,
      comfortRating: comfortRating ?? this.comfortRating,
      activitySuitability: activitySuitability ?? this.activitySuitability,
      compatibleAccessories: compatibleAccessories ?? this.compatibleAccessories,
    );
  }
}

class PurchaseSection {
  final String? brand;
  final String? productName;
  final dynamic purchaseDate;
  final double? purchasePrice;
  final String? purchaseCurrency;
  final String? purchaseSource;
  final String? storeName;
  final String? productUrl;
  final String? invoiceReference;
  final String? ownershipStatus;

  const PurchaseSection({
    this.brand,
    this.productName,
    this.purchaseDate,
    this.purchasePrice,
    this.purchaseCurrency = 'INR',
    this.purchaseSource,
    this.storeName,
    this.productUrl,
    this.invoiceReference,
    this.ownershipStatus,
  });

  PurchaseSection copyWith({
    String? brand,
    String? productName,
    dynamic purchaseDate,
    double? purchasePrice,
    String? purchaseCurrency,
    String? purchaseSource,
    String? storeName,
    String? productUrl,
    String? invoiceReference,
    String? ownershipStatus,
  }) {
    return PurchaseSection(
      brand: brand ?? this.brand,
      productName: productName ?? this.productName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseCurrency: purchaseCurrency ?? this.purchaseCurrency,
      purchaseSource: purchaseSource ?? this.purchaseSource,
      storeName: storeName ?? this.storeName,
      productUrl: productUrl ?? this.productUrl,
      invoiceReference: invoiceReference ?? this.invoiceReference,
      ownershipStatus: ownershipStatus ?? this.ownershipStatus,
    );
  }
}

class CareSection {
  final String? washingMethod;
  final String? washingTemperature;
  final bool? bleachAllowed;
  final String? ironingTemperature;
  final String? dryingMethod;
  final bool? dryCleaning;
  final String? careLabelInstructions;
  final List<String> carePrecautions;

  const CareSection({
    this.washingMethod,
    this.washingTemperature,
    this.bleachAllowed,
    this.ironingTemperature,
    this.dryingMethod,
    this.dryCleaning,
    this.careLabelInstructions,
    this.carePrecautions = const [],
  });
}

class PhysicalLocationSection {
  final String? storageLocation;
  final String? storageSection;
  final String? shelf;
  final String? drawer;
  final String? hangerSection;
  final String? storageContainer;
  final String? locationNotes;

  const PhysicalLocationSection({
    this.storageLocation,
    this.storageSection,
    this.shelf,
    this.drawer,
    this.hangerSection,
    this.storageContainer,
    this.locationNotes,
  });
}

class AiMetadataSection {
  final String detectionSource;
  final String? visionProvider;
  final String? imageGenerationProvider;
  final String? modelName;
  final String? processingTimestamp;
  final String schemaVersion;
  final Map<String, dynamic> attributeConfidence;
  final String verificationStatus;
  final List<String> userVerifiedFields;
  final List<String> userCorrectedFields;
  final List<String> uncertainFields;
  final List<String> unknownFields;

  const AiMetadataSection({
    this.detectionSource = 'user_uploaded_image',
    this.visionProvider,
    this.imageGenerationProvider,
    this.modelName,
    this.processingTimestamp,
    this.schemaVersion = '1.1',
    this.attributeConfidence = const {},
    this.verificationStatus = 'pending_user_review',
    this.userVerifiedFields = const [],
    this.userCorrectedFields = const [],
    this.uncertainFields = const [],
    this.unknownFields = const [],
  });
}

class VisualAssetsSection {
  final String? originalImageDescription;
  final String? catalogueImageDescription;
  final bool catalogueImageGenerated;
  final bool originalImagePreserved;

  const VisualAssetsSection({
    this.originalImageDescription,
    this.catalogueImageDescription,
    this.catalogueImageGenerated = false,
    this.originalImagePreserved = true,
  });
}

// ignore: camel_case_types
class GarmentMetadataV1_1 {
  final String schemaVersion;
  final String recordType;
  final IdentitySection identity;
  final AppearanceSection appearance;
  final ConstructionSection construction;
  final MaterialSection material;
  final SizingSection sizing;
  final UsageSection usage;
  final PurchaseSection purchase;
  final CareSection care;
  final PhysicalLocationSection physicalLocation;
  final Map<String, dynamic> categorySpecific;
  final AiMetadataSection aiMetadata;
  final VisualAssetsSection visualAssets;
  final List<String> notes;

  const GarmentMetadataV1_1({
    this.schemaVersion = '1.1',
    this.recordType = 'garment',
    this.identity = const IdentitySection(),
    this.appearance = const AppearanceSection(),
    this.construction = const ConstructionSection(),
    this.material = const MaterialSection(),
    this.sizing = const SizingSection(),
    this.usage = const UsageSection(),
    this.purchase = const PurchaseSection(),
    this.care = const CareSection(),
    this.physicalLocation = const PhysicalLocationSection(),
    this.categorySpecific = const {},
    this.aiMetadata = const AiMetadataSection(),
    this.visualAssets = const VisualAssetsSection(),
    this.notes = const [],
  });

  GarmentMetadataV1_1 copyWith({
    String? schemaVersion,
    String? recordType,
    IdentitySection? identity,
    AppearanceSection? appearance,
    ConstructionSection? construction,
    MaterialSection? material,
    SizingSection? sizing,
    UsageSection? usage,
    PurchaseSection? purchase,
    CareSection? care,
    PhysicalLocationSection? physicalLocation,
    Map<String, dynamic>? categorySpecific,
    AiMetadataSection? aiMetadata,
    VisualAssetsSection? visualAssets,
    List<String>? notes,
  }) {
    return GarmentMetadataV1_1(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      recordType: recordType ?? this.recordType,
      identity: identity ?? this.identity,
      appearance: appearance ?? this.appearance,
      construction: construction ?? this.construction,
      material: material ?? this.material,
      sizing: sizing ?? this.sizing,
      usage: usage ?? this.usage,
      purchase: purchase ?? this.purchase,
      care: care ?? this.care,
      physicalLocation: physicalLocation ?? this.physicalLocation,
      categorySpecific: categorySpecific ?? this.categorySpecific,
      aiMetadata: aiMetadata ?? this.aiMetadata,
      visualAssets: visualAssets ?? this.visualAssets,
      notes: notes ?? this.notes,
    );
  }
}
