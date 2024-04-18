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
  query GetCartItems(\$cartId: String!) {
    cart(cart_id: \$cartId) {
      email
      items {
        id
        product {
          name
          sku
          ... on ConfigurableProduct {
            variants {
              attributes {
                uid
                __typename
              }
            }
          }
          special_price
          price_range {
            __typename
            minimum_price {
              __typename
              regular_price {
                __typename
                value
                currency
              }
              final_price {
                __typename
                value
                currency
              }
              discount {
                __typename
                amount_off
              }
            }
          }
        }
        quantity
        ... on ConfigurableCartItem {
          configurable_options {
            configurable_product_option_uid
            configurable_product_option_value_uid
            option_label
            value_label
            id
          }
        }
        __typename
      }    
    }
  }
""";

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    print('Cart ID: ${cartProvider.id}');
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Resumen de pedido"),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getCartItemsQuery),
          variables: {'cartId': cartProvider.id}, // Usa el cartId del CartProvider
        ),
        builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
          if (result.hasException) {
            print('GraphQL Exception: ${result.exception.toString()}');
            return Text(result.exception.toString());
          }

          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          print('GraphQL Response: ${result.data}');

          if (result.data!['cart'] != null && result.data!['cart']['items'] != null) {
            final items = (result.data!['cart']['items'] as List)
                .map((item) => CartItem.fromJson(item))
                .toList();

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(item.product.sku),
                );
              },
            );
          } else {
            return Center(child: Text('No hay elementos en el carrito'));
          }
        },
      ),
    );
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final List<ConfigurableOption> configurableOptions;

  CartItem({
    required this.product,
    required this.quantity,
    this.configurableOptions = const [],
  });


  factory CartItem.fromJson(Map<String, dynamic> json) {
    var productJson = json['product'];
    var product = Product.fromJson(productJson);
    var quantity = json['quantity'];
    var optionsJson = json['configurable_options'] as List?;
    var options = optionsJson != null ? optionsJson.map((option) => ConfigurableOption.fromJson(option)).toList() : [];
    return CartItem(
      product: product,
      quantity: quantity,
      configurableOptions: options.cast<ConfigurableOption>(),
    );
  }
}

class Product {
  final String name;
  final String sku;
  final double? specialPrice;
  final PriceRange priceRange;

  Product({required this.name, required this.sku, this.specialPrice, required this.priceRange});

  factory Product.fromJson(Map<String, dynamic> json) {
    var priceRangeJson = json['price_range'];
    var priceRange = PriceRange.fromJson(priceRangeJson);
    return Product(
      name: json['name'],
      sku: json['sku'],
      specialPrice: json['special_price'],
      priceRange: priceRange,
    );
  }
}

class PriceRange {
  final double regularPrice;
  final double finalPrice;
  final double discount;

  PriceRange({required this.regularPrice, required this.finalPrice, required this.discount});

  factory PriceRange.fromJson(Map<String, dynamic> json) {
    var minimumPrice = json['minimum_price'];
    return PriceRange(
      regularPrice: (minimumPrice['regular_price']['value'] as num).toDouble(),
      finalPrice: (minimumPrice['final_price']['value'] as num).toDouble(),
      discount: (minimumPrice['discount']['amount_off'] as num).toDouble(),
    );
  }
}


class ConfigurableOption {
  final String uid;
  final String optionLabel;
  final String valueLabel;

  ConfigurableOption({required this.uid, required this.optionLabel, required this.valueLabel});

  factory ConfigurableOption.fromJson(Map<String, dynamic> json) {
    return ConfigurableOption(
      uid: json['configurable_product_option_uid'],
      optionLabel: json['option_label'],
      valueLabel: json['value_label'],
    );
  }
}


