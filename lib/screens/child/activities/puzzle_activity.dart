import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../utils/app_colors.dart';

class PuzzleActivity extends StatefulWidget {
  final String? imageUrl;
  final String itemName;
  final Function(bool) onComplete;

  const PuzzleActivity({
    super.key, 
    this.imageUrl, 
    required this.itemName, 
    required this.onComplete
  });

  @override
  State<PuzzleActivity> createState() => _PuzzleActivityState();
}

class _PuzzleActivityState extends State<PuzzleActivity> {
  late List<bool> _slotMatched;
  late List<int> _shuffledIndices;
  
  final double _boardSize = 320.0; 
  final double _trayPieceSize = 110.0; 

  @override
  void initState() {
    super.initState();
    _slotMatched = List.filled(4, false); 
    _shuffledIndices = List.generate(4, (index) => index)..shuffle();
  }

  void _checkWin() {
    if (_slotMatched.every((matched) => matched)) {
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onComplete(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          FadeInDown(
            child: Text(
              "FIX THE ${widget.itemName.toUpperCase()}!",
              style: const TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900, 
                color: AppColors.childNavy, 
                letterSpacing: 1.2
              ),
            ),
          ),
          const SizedBox(height: 25),

          // --- THE JIGSAW BOARD ---
          Container(
            width: _boardSize,
            height: _boardSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 1. Ghost Background (Guide)
                  Opacity(
                    opacity: 0.15,
                    child: Image.network(widget.imageUrl!, fit: BoxFit.fill, width: _boardSize, height: _boardSize),
                  ),

                  // 2. THE SEGMENT DIVIDERS (Visible lines on the board)
                  _buildBoardSegments(),

                  // 3. THE INTERACTIVE DROP SLOTS
                  _buildInteractionGrid(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 50),

          // --- THE PIECE TRAY ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 25,
              runSpacing: 25,
              alignment: WrapAlignment.center,
              children: _shuffledIndices.map((index) {
                if (_slotMatched[index]) {
                  return SizedBox(width: _trayPieceSize, height: _trayPieceSize);
                }

                return Draggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildSlicedFragment(index, size: _trayPieceSize, isDragging: true),
                  ),
                  childWhenDragging: Opacity(opacity: 0, child: _buildSlicedFragment(index, size: _trayPieceSize)),
                  child: _buildSlicedFragment(index, size: _trayPieceSize),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI: DRAWS THE CROSS-HAIR DIVIDERS ---
  Widget _buildBoardSegments() {
    return Stack(
      children: [
        // Vertical Divider
        Center(child: Container(width: 3, color: Colors.white.withOpacity(0.8))),
        // Horizontal Divider
        Center(child: Container(height: 3, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildInteractionGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildDropSlot(0)),
              Expanded(child: _buildDropSlot(1)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildDropSlot(2)),
              Expanded(child: _buildDropSlot(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropSlot(int index) {
    return DragTarget<int>(
      onAcceptWithDetails: (details) {
        if (details.data == index) {
          setState(() => _slotMatched[index] = true);
          _checkWin();
        } else {
          widget.onComplete(false);
        }
      },
      builder: (context, candidate, rejected) {
        return Container(
          decoration: BoxDecoration(
            // Highlight the slot if a piece is hovering over it
            color: candidate.isNotEmpty ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            // Draw a subtle dashed-look border for the segment
            border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
          ),
          child: _slotMatched[index] 
              ? _buildSlicedFragment(index, size: _boardSize / 2, isOnBoard: true) 
              : const Center(child: Icon(Icons.add, color: Colors.black12, size: 30)),
        );
      },
    );
  }

  // --- THE TRUE FRAGMENT ENGINE (STAYS THE SAME AS PREVIOUS CORRECT ONE) ---
  Widget _buildSlicedFragment(int index, {required double size, bool isDragging = false, bool isOnBoard = false}) {
    double left = (index % 2 == 0) ? 0 : -size;
    double top = (index < 2) ? 0 : -size;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isOnBoard ? 0 : 15),
        boxShadow: isOnBoard ? null : [
          BoxShadow(color: Colors.black.withOpacity(isDragging ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: isOnBoard ? null : Border.all(color: Colors.white, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isOnBoard ? 0 : 12),
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Image.network(
                widget.imageUrl!,
                width: size * 2,
                height: size * 2,
                fit: BoxFit.fill,
                errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
              ),
            ),
          ],
        ),
      ),
    );
  }
}