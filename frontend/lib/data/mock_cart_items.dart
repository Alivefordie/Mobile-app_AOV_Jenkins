import 'package:flutter_application_1/models/cart_item.dart';

const List<CartItem> mockCartItems = [
  CartItem(
    id: 'mock-tom-yum',
    title: 'ต้มยำกุ้งน้ำข้น',
    imageUrl:
        'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80',
    price: 129,
  ),
  CartItem(
    id: 'mock-pad-krapow',
    title: 'ผัดกะเพราหมูสับไข่ดาว',
    imageUrl:
        'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=400&q=80',
    price: 89,
    quantity: 2,
  ),
  CartItem(
    id: 'mock-green-curry',
    title: 'แกงเขียวหวานไก่',
    imageUrl:
        'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400&q=80',
    price: 149,
  ),
  CartItem(
    id: 'mock-mango-sticky-rice',
    title: 'ข้าวเหนียวมะม่วง',
    imageUrl:
        'https://images.unsplash.com/photo-1621293954908-907159247fc8?w=400&q=80',
    price: 99,
  ),
];
