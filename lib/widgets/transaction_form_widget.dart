import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../controllers/transaction_controller.dart';
import '../utils/currency_formatter.dart';
import '../providers/auth_provider.dart';

class TransactionFormWidget extends StatefulWidget {
  final TransactionController controller;
  final String currentTime;
  final VoidCallback onFormChanged;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  const TransactionFormWidget({
    Key? key,
    required this.controller,
    required this.currentTime,
    required this.onFormChanged,
    required this.onSubmit,
    required this.onReset,
  }) : super(key: key);

  @override
  State<TransactionFormWidget> createState() => _TransactionFormWidgetState();
}

class _TransactionFormWidgetState extends State<TransactionFormWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.nominalController.addListener(() {
      widget.controller.onNominalInput(widget.onFormChanged);
    });
    widget.controller.tambahanController.addListener(() {
      widget.controller.onTambahanInput(widget.onFormChanged);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cashierName =
        auth.user?['name']?.toString() ??
        auth.user?['username']?.toString() ??
        'Kasir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Row 1: Tanggal & Waktu and Kasir
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyField(
                'Tanggal & Waktu',
                widget.currentTime,
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReadOnlyField('Kasir', cashierName, Icons.person),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 2: Mesin EDC and Jenis Layanan
        Row(
          children: [
            Expanded(
              child: widget.controller.isLoadingMachines
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                      value: widget.controller.selectedMachine,
                      items: [
                        '-- Pilih Mesin --',
                        ...widget.controller.edcMachines.map(
                          (m) => (m['name'] ?? '').toString(),
                        ),
                      ],
                      label: 'Mesin EDC',
                      icon: Icons.point_of_sale,
                      onChanged: (v) => widget.controller.onMachineChanged(
                        v,
                        widget.onFormChanged,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: widget.controller.isLoadingServices
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                      value: widget.controller.selectedService,
                      items: [
                        '-- Pilih Layanan --',
                        ...widget.controller.services.map(
                          (s) => (s['name'] ?? '').toString(),
                        ),
                      ],
                      label: 'Jenis Layanan',
                      icon: Icons.category,
                      onChanged: (v) => widget.controller.onServiceChanged(
                        v,
                        widget.onFormChanged,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 3: Nominal and Biaya Tambahan
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller.nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.briBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: widget.controller.tambahanController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  // Format biaya tambahan dengan thousand separator
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.isEmpty) {
                    widget.controller.tambahanController.text = '0';
                    widget
                        .controller
                        .tambahanController
                        .selection = TextSelection.collapsed(
                      offset: widget.controller.tambahanController.text.length,
                    );
                  } else {
                    final numValue = double.tryParse(digits) ?? 0.0;
                    final formatted = CurrencyFormatter.formatNumberNoDecimals(
                      numValue,
                    );
                    widget.controller.tambahanController.text = formatted;
                    widget
                        .controller
                        .tambahanController
                        .selection = TextSelection.collapsed(
                      offset: widget.controller.tambahanController.text.length,
                    );
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Biaya Tambahan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 4: Biaya Layanan dan Biaya Admin Bank (editable)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller.serviceFeeController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (widget.controller.isFormattingServiceFee) return;
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  widget.controller.isFormattingServiceFee = true;
                  final formatted = digits.isEmpty
                      ? '0'
                      : CurrencyFormatter.formatNumberNoDecimals(
                          double.tryParse(digits) ?? 0.0,
                        );
                  setState(() {
                    widget.controller.serviceFeeController.text = formatted;
                    widget.controller.serviceFeeController.selection =
                        TextSelection.collapsed(offset: formatted.length);
                    widget.controller.serviceFeeDisplay = 'Rp$formatted';
                  });
                  widget.controller.isFormattingServiceFee = false;
                  widget.controller.updateTotalBiaya();
                  widget.onFormChanged();
                },
                decoration: InputDecoration(
                  labelText: 'Biaya Layanan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: widget.controller.bankFeeController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (widget.controller.isFormattingBankFee) return;
                  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                  widget.controller.isFormattingBankFee = true;
                  final formatted = digits.isEmpty
                      ? '0'
                      : CurrencyFormatter.formatNumberNoDecimals(
                          double.tryParse(digits) ?? 0.0,
                        );
                  setState(() {
                    widget.controller.bankFeeController.text = formatted;
                    widget.controller.bankFeeController.selection =
                        TextSelection.collapsed(offset: formatted.length);
                    widget.controller.bankFeeDisplay = 'Rp$formatted';
                  });
                  widget.controller.isFormattingBankFee = false;
                  widget.controller.updateTotalBiaya();
                  widget.onFormChanged();
                },
                decoration: InputDecoration(
                  labelText: 'Biaya Admin Bank',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 5: Total Biaya (full width)
        _buildFeeField(
          'Total Biaya',
          widget.controller.totalFeesController,
          Icons.paid,
        ),
        const SizedBox(height: 16),

        // Row 6: Nama Pelanggan and Nomor Tujuan
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller.customerNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: widget.controller.destinationNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Tujuan',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Row 7: Keterangan (full width)
        TextFormField(
          controller: widget.controller.keteranganController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Keterangan',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),

        // Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onReset,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.briBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFeeField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.briBlue, width: 2),
        ),
      ),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
