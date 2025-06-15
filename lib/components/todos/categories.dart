import 'package:flutter/material.dart';
import 'package:school_day/screens/todos/add_category_page.dart';
import 'package:school_day/services/database/todo/category.dart';
import 'package:school_day/styles/styles.dart';

class Categories extends StatefulWidget {
  const Categories({
    super.key,
    required this.currentCategoryID,
    required this.categories,
    required this.categoryDocument,
  });

  final String currentCategoryID;
  final List<CategoryInfo> categories;
  final CategoryDocument categoryDocument;

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 150,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3 / 2,
      ),
      itemCount: widget.categories.length + 1,
      itemBuilder: (context, index) {
        bool isAddButton = index == widget.categories.length;
        bool isSelected = !isAddButton &&
            widget.categories[index].id == widget.currentCategoryID;

        return Card(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          color: isSelected ? secondaryColor : Colors.white,
          child: InkWell(
            onTap: () async {
              if (isAddButton) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: AddCategoryPage(
                          isEdited: false,
                          isCurrent: isSelected,
                          categoryDocument: widget.categoryDocument,
                        ),
                      ),
                    );
                  },
                );
              } else {
                if (context.mounted) {
                  Navigator.pop(context);
                }

                await widget.categoryDocument.updateCurrentTodosID(
                  widget.categories[index].id,
                );
              }
            },
            onLongPress: () {
              if (!isAddButton) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: AddCategoryPage(
                          isEdited: true,
                          isCurrent: isSelected,
                          categoryDocument: widget.categoryDocument,
                          name: widget.categories[index].name,
                          categoryID: widget.categories[index].id,
                        ),
                      ),
                    );
                  },
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAddButton)
                      const Column(
                        spacing: 16,
                        children: [
                          Icon(Icons.add_rounded),
                          Text('สร้างหมวดหมู่งานใหม่'),
                        ],
                      )
                    else
                      Column(
                        spacing: 16,
                        children: [
                          Text(
                            widget.categories[index].name,
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected) const Icon(Icons.check_rounded),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
