import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../utils/app_colors.dart';
import '../parent/parent_dashboard.dart';
import 'learning_map.dart';
import 'resource_grid_screen.dart';

class ChildHomeScreen extends StatelessWidget {
  final ChildProfile child;
  const ChildHomeScreen({super.key, required this.child});

  // Categorical logic: 'map' type is for A-Z / 1-10. 'grid' is for Animals / Skills.
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Alphabets', 'icon': Icons.abc_rounded, 'color': Color(0xFFFF7043), 'type': 'map', 'desc': 'Tracing & Phonics'},
    {'name': 'Numbers', 'icon': Icons.calculate_rounded, 'color': Color(0xFF3F51B5), 'type': 'map', 'desc': 'Counting & Math'},
    {'name': 'Animals', 'icon': Icons.pets_rounded, 'color': Color(0xFF00BFA5), 'type': 'grid', 'desc': 'Sounds & Nature'},
    {'name': 'Shapes', 'icon': Icons.category_rounded, 'color': Colors.purple, 'type': 'grid', 'desc': 'Colors & Geometry'},
    {'name': 'Social Skills', 'icon': Icons.volunteer_activism_rounded, 'color': Colors.pink, 'type': 'grid', 'desc': 'Manners & Emotion'},
    {'name': 'Life Skills', 'icon': Icons.directions_run_rounded, 'color': Colors.blueGrey, 'type': 'grid', 'desc': 'Safety & Care'},
  ];

  void _openParentLock(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Parents Only", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Solve this to unlock settings:"),
            const SizedBox(height: 15),
            const Text("12 + 5 = ?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            const SizedBox(height: 10),
            TextField(
              controller: controller, 
              keyboardType: TextInputType.number, 
              autofocus: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "Answer"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (controller.text == "17") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ParentDashboard(specificChild: child)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try again, Parent!")));
              }
            }, 
            child: const Text("Unlock", style: TextStyle(fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 20, 
                mainAxisSpacing: 20, 
                childAspectRatio: 0.85
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCategoryCard(context, categories[index]),
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    return InkWell(
      borderRadius: BorderRadius.circular(35),
      onTap: () {
        if (cat['type'] == 'map') {
          Navigator.push(context, MaterialPageRoute(builder: (c) => LearningMapScreen(child: child, category: cat['name'])));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (c) => ResourceGridScreen(child: child, category: cat['name'])));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: cat['color'].withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: cat['color'].withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(cat['icon'], size: 45, color: cat['color']),
            ),
            const SizedBox(height: 15),
            Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
            Text(cat['desc'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160, 
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: Text("Hi, ${child.name}!", 
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 24)),
        background: Container(color: Colors.white),
      ),
      actions: [
        GestureDetector(
          onLongPress: () => _openParentLock(context),
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 10),
            child: CircleAvatar(
              radius: 30, 
              backgroundColor: AppColors.lavender,
              backgroundImage: NetworkImage(child.avatarUrl)
            ),
          ),
        ),
      ],
    );
  }
}