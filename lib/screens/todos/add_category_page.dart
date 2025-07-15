import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/services/database/todo/category.dart';
import 'package:school_day/styles/styles.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({
    super.key,
    required this.isEdited,
    required this.isCurrent,
    required this.categoryDocument,
    this.name,
    this.categoryID,
  });

  final bool isEdited;
  final bool isCurrent;
  final CategoryDocument categoryDocument;
  final String? name;
  final String? categoryID;

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();

  String _initialValue = '';
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();

    if (widget.name != null) {
      _categoryNameController.text = widget.name!;
      _initialValue = _categoryNameController.text;
    }

    _categoryNameController.addListener(() {
      final currentValue = _categoryNameController.text;

      setState(() {
        _hasChanged = currentValue != _initialValue;
      });
    });
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.cancel_rounded),
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              !widget.isEdited ? 'เพิ่มหมวดหมู่งานใหม่' : 'แก้ไขหมวดหมู่งาน',
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Flexible(
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _categoryNameController,
                      decoration: const InputDecoration(
                        hintText: 'ชื่อหมวดหมู่งาน',
                      ),
                      maxLength: 25,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'กรุณากรอกชื่อหมวดหมู่งานด้วยนะงับ';
                        }

                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                FilledButton.tonal(
                  onPressed: !_hasChanged
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: LoadingAnimationWidget.fourRotatingDots(
                                  color: primaryColor,
                                  size: 80,
                                ),
                              ),
                            );

                            if (!widget.isEdited) {
                              await widget.categoryDocument.createNewCategory(
                                name: _categoryNameController.text.trim(),
                              );
                            } else {
                              await widget.categoryDocument.updateCategory(
                                name: _categoryNameController.text.trim(),
                                categoryID: widget.categoryID!,
                              );
                            }

                            if (!context.mounted) return;

                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                  child: const Icon(Icons.save_rounded),
                ),
              ],
            ),
            if (widget.isEdited)
              Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.isCurrent
                              ? null
                              : () async {
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        content: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'คุณต้องการลบหมวดหมู่งานใช่ไหม :<',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('ยกเลิก'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text('ลบ'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirmDelete != true ||
                                      !context.mounted) {
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Center(
                                      child: LoadingAnimationWidget
                                          .fourRotatingDots(
                                        color: primaryColor,
                                        size: 80,
                                      ),
                                    ),
                                  );

                                  await widget.categoryDocument.deleteCategory(
                                    categoryID: widget.categoryID!,
                                  );

                                  if (!context.mounted) return;

                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                          icon: const Icon(Icons.delete_rounded),
                          label: Text(
                            widget.isCurrent
                                ? 'กรุณาเปลี่ยน หรือเพิ่มหมวดหมู่งานเพื่อลบ'
                                : 'ลบหมวดหมู่งาน',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
