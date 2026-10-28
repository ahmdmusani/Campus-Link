import 'dart:ui';
import 'package:flutter/material.dart';

class AdvancedLnFGrid extends StatelessWidget {
  const AdvancedLnFGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Lost & Found', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: IconButton(icon: const Icon(Icons.search, color: Color(0xFF1A237E)), onPressed: () {}),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFilterChip('All Items', true),
                const SizedBox(width: 8),
                _buildFilterChip('Lost', false),
                const SizedBox(width: 8),
                _buildFilterChip('Found', false),
                const Spacer(),
                _buildFilterChip('', false, icon: Icons.tune),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return _buildGridItem(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1A237E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
          if (icon != null) ...[
            if (label.isNotEmpty) const SizedBox(width: 4),
            Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF1A237E)),
          ]
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, int index) {
    bool isFound = index % 2 == 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Carousel Placeholder
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isFound ? const Color(0xFFFBE9E7) : const Color(0xFFE8EAF6),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: PageView(
                    children: [
                      Center(child: Icon(isFound ? Icons.backpack_rounded : Icons.menu_book_rounded, size: 60, color: isFound ? Colors.deepOrangeAccent : const Color(0xFF1A237E))),
                      Center(child: Icon(Icons.photo_library_outlined, size: 50, color: Colors.black26)),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFound ? 'Found' : 'Lost',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isFound ? Colors.deepOrange : const Color(0xFF1A237E)),
                    ),
                  ),
                ),
                // Mock Page Indicator
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 4),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Info Section
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFound ? 'Red Backpack' : 'CS Notebook', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.black45),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isFound ? 'CS Department' : 'Main Library', 
                              style: const TextStyle(color: Colors.black54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('2 hours ago', style: TextStyle(color: Colors.black38, fontSize: 10)),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E).withOpacity(0.08),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Contact Finder', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
