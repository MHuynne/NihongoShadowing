import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_colors.dart';

class ShadowingHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final bool isBlindMode;
  final ValueChanged<bool> onModeChanged;

  const ShadowingHeader({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.isBlindMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
               GestureDetector(
                onTap: () {
                  // Hiển thị dialog xác nhận nếu muốn hoặc back về luồng trước / thoát thẳng về home
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightPinkBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.sunRed, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBlindMode)
                    const Text(
                      'STAGE 2: BLIND\nSHADOWING',
                      style: TextStyle(
                        color: AppColors.sunRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  Text(
                    'Câu $currentIndex/$totalCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Toggle Switch Design
          Container(
             decoration: BoxDecoration(
               color: Colors.white.withOpacity(0.85),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: AppColors.sunRed.withOpacity(0.2)),
             ),
             child: isBlindMode ? _buildBlindSwitch() : _buildNormalToggle(),
          )
        ],
      ),
    );
  }

  Widget _buildNormalToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onModeChanged(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
               color: !isBlindMode ? Colors.white.withOpacity(0.9) : Colors.transparent,
               borderRadius: BorderRadius.circular(20),
               boxShadow: !isBlindMode ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
            ),
            child: Text(
              'Có chữ',
              style: TextStyle(
                color: !isBlindMode ? AppColors.sunRed : AppColors.slate500,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onModeChanged(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
               color: isBlindMode ? Colors.white.withOpacity(0.9) : Colors.transparent,
               borderRadius: BorderRadius.circular(20),
               boxShadow: isBlindMode ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
            ),
            child: Text(
              'Ẩn chữ',
              style: TextStyle(
                color: isBlindMode ? AppColors.textDark : AppColors.slate500,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlindSwitch() {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           const Text(
             'Ẩn\nchữ',
             style: TextStyle(color: AppColors.slate600, fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
           ),
           const SizedBox(width: 8),
           SizedBox(
             width: 36,
             height: 20,
             child: Switch(
               value: isBlindMode,
               onChanged: onModeChanged,
               activeColor: Colors.white,
               activeTrackColor: AppColors.slate300,
               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
             ),
           ),
         ],
       ),
     );
  }
}
