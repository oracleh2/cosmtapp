import 'package:flutter/material.dart';
import 'package:skin_analyzer/models/cosmetic_product.dart';

class ProductItem extends StatelessWidget {
  final CosmeticProduct product;
  final VoidCallback? onTap;

  const ProductItem({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение продукта
            AspectRatio(
              aspectRatio: 1.5,
              child: product.imageUrl != null
                  ? Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.spa,
                    color: Theme.of(context).primaryColor,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Информация о продукте
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Бренд
                  Text(
                    product.brand,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Название продукта
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Категория
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Рейтинг
                  if (product.rating != null)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                              (index) => Icon(
                            index < product.rating!.floor()
                                ? Icons.star
                                : (index < product.rating!
                                ? Icons.star_half
                                : Icons.star_border),
                            color: Colors.amber,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating!.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                  // Для какого типа кожи
                  if (product.skinTypeTarget != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.face,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.skinTypeTarget!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Причина рекомендации
                  if (product.recommendationReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      product.recommendationReason!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}