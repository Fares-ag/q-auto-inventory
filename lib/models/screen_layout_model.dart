// lib/models/screen_layout_model.dart

class FieldDefinition {
  String id;
  String label; // The text shown in the UI (e.g., "Purchase Price")
  String
      attribute; // The actual attribute name in ItemModel (e.g., "purchasePrice")
  int order;
  bool isVisible;
  bool isRequired;

  FieldDefinition({
    required this.id,
    required this.label,
    required this.attribute,
    this.order = 0,
    this.isVisible = true,
    this.isRequired = false,
  });
}

class ScreenSection {
  String id;
  String
      title; // The title of the expandable section (e.g., "Purchase Details")
  int order;
  bool isVisible;
  List<FieldDefinition> fields;

  ScreenSection({
    required this.id,
    required this.title,
    this.order = 0,
    this.isVisible = true,
    required this.fields,
  });
}
