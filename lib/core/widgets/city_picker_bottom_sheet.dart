import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/pexels_photo_service.dart';
import 'city_photo_widget.dart';

/// iOS tarzı şehir seçim bottom sheet — arama destekli, fotoğraflı 81 il
class CityPickerBottomSheet extends StatefulWidget {
  final String title;
  final String? currentCity;

  const CityPickerBottomSheet({
    super.key,
    required this.title,
    this.currentCity,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? currentCity,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerBottomSheet(
        title: title,
        currentCity: currentCity,
      ),
    );
  }

  @override
  State<CityPickerBottomSheet> createState() => _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState extends State<CityPickerBottomSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = PexelsCityPhotoService.turkeyProvinces;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = PexelsCityPhotoService.searchProvinces(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.88;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // ── Header ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                    letterSpacing: 0.38,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.secondaryLabel,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── iOS Search Bar ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                style: GoogleFonts.inter(
                  color: AppColors.label,
                  fontSize: 17,
                  letterSpacing: -0.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Şehir ara...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.tertiaryLabel,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.tertiaryLabel,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Sonuç sayısı ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _filtered.isEmpty
                    ? 'Şehir bulunamadı'
                    : '${_filtered.length} il',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.tertiaryLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Şehir Listesi ───────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, index) {
                      final city = _filtered[index];
                      final isSelected = city == widget.currentCity;
                      return _CityListTile(
                        city: city,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(city);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.tertiaryLabel, size: 44),
          const SizedBox(height: 12),
          Text(
            '"${_searchController.text}" bulunamadı',
            style: GoogleFonts.inter(
              color: AppColors.secondaryLabel,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── iOS List Tile ─────────────────────────────────────────────────
class _CityListTile extends StatelessWidget {
  final String city;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityListTile({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Şehir fotoğrafı (avatar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: WikiCityImage(
                  city: city,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Şehir adı
            Expanded(
              child: Text(
                city,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.label,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            // Seçim işareti
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.tertiaryLabel,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
