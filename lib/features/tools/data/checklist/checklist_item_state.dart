class ChecklistItemState {
  final String status;
  final String? notes;

  const ChecklistItemState({
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        if (notes != null) 'notes': notes,
      };

  factory ChecklistItemState.fromJson(Map<String, dynamic> json) =>
      ChecklistItemState(
        status: json['status'] as String,
        notes: json['notes'] as String?,
      );
}
