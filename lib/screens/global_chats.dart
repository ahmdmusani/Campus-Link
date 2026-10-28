import 'package:flutter/material.dart';
import 'individual_chat.dart';

class GlobalChats extends StatelessWidget {
  const GlobalChats({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Chats', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 28)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildChatListItem(context, index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1A237E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_square, color: Colors.white),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, int index) {
    bool isGroup = index == 0;
    bool isTyping = index == 1;
    bool isUnread = index < 2;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const IndividualChat()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            _buildAvatar(isGroup),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGroup ? 'CS Study Group (3)' : 'Ayesha M.', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                      ),
                      Text(
                        index == 0 ? 'Now' : '3:44 PM', 
                        style: TextStyle(color: isUnread ? const Color(0xFF1A237E) : Colors.black45, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: isTyping
                            ? const Text('Typing...', style: TextStyle(color: Color(0xFF50C878), fontSize: 14, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic))
                            : const Text('Here coordination details...', style: TextStyle(color: Colors.black54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (isUnread && !isTyping)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle),
                          child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isGroup) {
    if (isGroup) {
      return SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF3949AB),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF50C878),
                  child: Icon(Icons.person_outline, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const CircleAvatar(
        radius: 25,
        backgroundColor: Color(0xFFE8EAF6),
        child: Icon(Icons.person, color: Color(0xFF1A237E), size: 28),
      );
    }
  }
}
