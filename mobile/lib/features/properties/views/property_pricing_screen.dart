import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

class PropertyPricingScreen extends StatefulWidget {
  final String homestayId;

  const PropertyPricingScreen({super.key, required this.homestayId});

  @override
  State<PropertyPricingScreen> createState() => _PropertyPricingScreenState();
}

class _PropertyPricingScreenState extends State<PropertyPricingScreen> {
  final _weekdayController = TextEditingController(text: '4.500.000');
  final _fridayController = TextEditingController(text: '6.500.000');
  final _saturdayController = TextEditingController(text: '6.500.000');
  final _sundayController = TextEditingController(text: '5.500.000');

  final List<_HolidayPrice> _holidayPrices = [
    _HolidayPrice(
      title: 'Lễ Giỗ Tổ 25-27/4',
      price: '11.000.000',
    ),
    _HolidayPrice(
      title: 'Lễ 30/4 - 1/5',
      price: '12.000.000',
    ),
  ];

  final List<String> _notes = [
    'Giá đã bao gồm bữa sáng cho 2 người',
    'Phụ thu thêm người: 200.000đ/người/đêm',
    'Check-in: 14:00 | Check-out: 12:00',
  ];

  @override
  void dispose() {
    _weekdayController.dispose();
    _fridayController.dispose();
    _saturdayController.dispose();
    _sundayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng giá'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSectionLabel('GIÁ CƠ BẢN'),
          const SizedBox(height: AppSpacing.sm),
          _buildBasePriceSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionLabel('GIÁ LỄ / SỰ KIỆN'),
          const SizedBox(height: AppSpacing.sm),
          _buildHolidayPriceSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionLabel('GHI CHÚ GIÁ'),
          const SizedBox(height: AppSpacing.sm),
          _buildNotesSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildSaveButton(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildBasePriceSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildPriceRow('Ngày thường (T2-T5)', _weekdayController),
          const Divider(height: 1, color: AppColors.border),
          _buildPriceRow('Thứ 6', _fridayController),
          const Divider(height: 1, color: AppColors.border),
          _buildPriceRow('Thứ 7', _saturdayController),
          const Divider(height: 1, color: AppColors.border),
          _buildPriceRow('Chủ nhật', _sundayController),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PriceInputFormatter(),
              ],
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ocean,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.sm,
                ),
                suffixText: 'đ',
                suffixStyle: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ocean,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayPriceSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _holidayPrices.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.border),
                _buildHolidayItem(i),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAddButton('Thêm mùa giá', _showAddHolidayDialog),
      ],
    );
  }

  Widget _buildHolidayItem(int index) {
    final item = _holidayPrices[index];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.price}đ/đêm',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _holidayPrices.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _notes.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.border),
                _buildNoteItem(i),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildAddButton('Thêm ghi chú', _showAddNoteDialog),
      ],
    );
  }

  Widget _buildNoteItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _notes[index],
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _notes.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppColors.ocean,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ocean,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.oceanMid, AppColors.ocean],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ElevatedButton(
          onPressed: () {
            AppSnackBar.success(context, 'Đã lưu bảng giá');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(
            'Lưu',
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddHolidayDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thêm mùa giá',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Tên mùa giá',
                labelStyle: GoogleFonts.beVietnamPro(fontSize: 14),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.beVietnamPro(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá (VNĐ)',
                labelStyle: GoogleFonts.beVietnamPro(fontSize: 14),
                border: const OutlineInputBorder(),
                suffixText: 'đ',
              ),
              style: GoogleFonts.beVietnamPro(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Huỷ',
              style: GoogleFonts.beVietnamPro(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final price = priceController.text.trim();
              if (title.isNotEmpty && price.isNotEmpty) {
                setState(() {
                  _holidayPrices.add(
                    _HolidayPrice(title: title, price: price),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ocean,
            ),
            child: Text(
              'Thêm',
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((_) {
      titleController.dispose();
      priceController.dispose();
    });
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Thêm ghi chú',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Nội dung ghi chú',
            labelStyle: GoogleFonts.beVietnamPro(fontSize: 14),
            border: const OutlineInputBorder(),
          ),
          style: GoogleFonts.beVietnamPro(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Huỷ',
              style: GoogleFonts.beVietnamPro(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final note = noteController.text.trim();
              if (note.isNotEmpty) {
                setState(() {
                  _notes.add(note);
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ocean,
            ),
            child: Text(
              'Thêm',
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((_) {
      noteController.dispose();
    });
  }
}

class _HolidayPrice {
  final String title;
  final String price;

  const _HolidayPrice({required this.title, required this.price});
}

class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final digits = newValue.text.replaceAll('.', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
