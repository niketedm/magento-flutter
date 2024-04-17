import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import '../../provider/cart.dart';

import '../../utils.dart'; // Asegúrate de que tu endpoint GraphQL está definido aquí

class CartTabs extends StatefulWidget {
  const CartTabs({Key? key}) : super(key: key);

  @override
  _CartTabsState createState() => _CartTabsState();
}


class _CartTabsState extends State<CartTabs> {
  final String getCartItemsQuery = """
  query GetCartItems(\$cartId: ID!) {
    cart(id: \$cartId) {
      id
      items {
        id
        quantity
        product {
          id
          name
          description
          imageUrl
          price
        }
      }
    }
  }
""";


  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Shopping Cart"),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getCartItemsQuery),
          variables: {'cartId': cartProvider.id}, // Usa el cartId del CartProvider
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = (result.data!['cart']['items'] as List)
              .map((item) => CartItem.fromJson(item))
              .toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CachedNetworkImage(
                  imageUrl: item.product.imageUrl,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
                title: Text(item.product.name),
                subtitle: Text(item.product.description),
                trailing: Text('${item.product.price}'),
              );
            },
          );
        },
      ),
    );
  }
}

class CartItem {
  final Product product;

  CartItem({required this.product});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
    );
  }
}

class Product {
  final String name;
  final String description;
  final String imageUrl;
  final double price;

  Product({required this.name, required this.description, required this.imageUrl, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
    );
  }
}