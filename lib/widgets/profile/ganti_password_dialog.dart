import 'package:flutter/material.dart';
import 'package:finansisten/widgets/profile/profile_constants.dart';
import 'package:finansisten/services/auth_service.dart';

class GantiPasswordDialog extends StatefulWidget {
  const GantiPasswordDialog({
    super.key,
    required this.onSave,
    required this.onError,
  });

  final Future<void> Function(String newPassword) onSave;
  final void Function(String message) onError;

  @override
  State<GantiPasswordDialog> createState() => _GantiPasswordDialogState();
}

class _GantiPasswordDialogState extends State<GantiPasswordDialog> {
  final _auth = AuthService.instance;

  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirmPass = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      widget.onError("Semua field wajib diisi");
      return;
    }

    if (newPass.length < 6) {
      widget.onError("Password baru minimal 6 karakter");
      return;
    }

    if (newPass != confirmPass) {
      widget.onError("Konfirmasi password tidak sama");
      return;
    }

    setState(() => _isLoading = true);

    final success = await _auth.updatePassword(oldPass, newPass);

    setState(() => _isLoading = false);

    if (!success) {
      widget.onError("Password lama tidak sesuai");
      return;
    }

    await widget.onSave(newPass);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ganti Password",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 20),

            _passwordField("Password Lama", _oldCtrl, _hideOld,
                () => setState(() => _hideOld = !_hideOld)),
            const SizedBox(height: 14),

            _passwordField("Password Baru", _newCtrl, _hideNew,
                () => setState(() => _hideNew = !_hideNew)),
            const SizedBox(height: 14),

            _passwordField("Konfirmasi Password Baru", _confirmCtrl,
                _hideConfirm, () => setState(() => _hideConfirm = !_hideConfirm)),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Batal",
                      style: TextStyle(color: kAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Simpan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController controller,
    bool hide,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: kFieldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: hide,
                  style: const TextStyle(fontSize: 15, color: kPrimary),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  hide ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: kAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}