import 'dart:async';

import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key, required this.onSearch});

  // ส่งคำค้นหาออกไปหลังผู้ใช้หยุดพิมพ์ ถ้าได้ค่าว่างคือยกเลิกการค้นหา
  final ValueChanged<String> onSearch;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // หน่วงก่อนยิง API ไม่งั้นพิมพ์ 1 ตัวอักษรจะยิง 1 ครั้ง
  static const _debounceDuration = Duration(milliseconds: 400);

  final _controller = TextEditingController();
  Timer? _debounce;
  String _lastSent = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _submit(value));
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    _submit(value);
  }

  void _submit(String value) {
    final query = value.trim();
    // กันยิงซ้ำคำเดิม เช่น พิมพ์เว้นวรรคท้ายคำ หรือกด enter ซ้ำ
    if (query == _lastSent) return;
    _lastSent = query;
    widget.onSearch(query);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _submit('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                const Icon(Icons.search),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _onSubmitted,
                    decoration: const InputDecoration(
                      hintText: "Search food",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                // ปุ่มล้างคำค้นหา โผล่เฉพาะตอนมีข้อความในช่อง
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: _clear,
                      child: const Icon(Icons.close, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.notifications_none),
        )
      ],
    );
  }
}
