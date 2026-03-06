import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/supabase_client.dart';
import '../core/onboarding_state.dart';
import '../providers/app_provider.dart';
import '../services/user_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showUsernameEditSheet(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.username ?? '');
    String? usernameStatus;
    String lastChecked = '';
    final formKey = GlobalKey<FormState>();
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> checkAvailability(String value) async {
              final trimmed = value.trim().toLowerCase();
              if (trimmed == lastChecked) return;
              lastChecked = trimmed;
              if (!regex.hasMatch(trimmed)) {
                setSheetState(() => usernameStatus = 'invalid');
                return;
              }
              setSheetState(() => usernameStatus = 'checking');
              final available = await UserDataService.isUsernameAvailable(trimmed);
              if (lastChecked != trimmed) return;
              setSheetState(() =>
                  usernameStatus = available ? 'available' : 'taken');
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24,
                  MediaQuery.of(context).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Change Username',
                      style: GoogleFonts.lora(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppTheme.ink),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        suffixIcon: usernameStatus == 'available'
                            ? Icon(Icons.check_circle_outline,
                                color: AppTheme.sage, size: 20)
                            : usernameStatus == 'taken'
                                ? Icon(Icons.cancel_outlined,
                                    color: AppTheme.sienna, size: 20)
                                : null,
                      ),
                      autocorrect: false,
                      onChanged: (v) {
                        if (v.length >= 3) {
                          Future.delayed(
                              const Duration(milliseconds: 400),
                              () => checkAvailability(v));
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!regex.hasMatch(v.trim().toLowerCase()))
                          return 'Use lowercase letters, numbers and underscores (3–20 chars)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: usernameStatus != 'available'
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final userId =
                                  supabase.auth.currentUser?.id;
                              if (userId == null) return;
                              await provider.setUsername(
                                  userId,
                                  controller.text.trim().toLowerCase());
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.page,
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'How Scroll Books works',
                    style: GoogleFonts.nunito(
                      color: AppTheme.ink,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () => context.push('/onboarding'),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Reading style',
                    style: GoogleFonts.nunito(
                      color: AppTheme.ink,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.readingStyle == 'horizontal'
                            ? 'Stories Style'
                            : 'Scroll Style',
                        style: TextStyle(color: AppTheme.pewter),
                      ),
                      Icon(Icons.chevron_right, color: AppTheme.pewter),
                    ],
                  ),
                  onTap: () => context.push('/app/profile/reading-style'),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Username',
                    style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.username != null)
                        Text('@${provider.username}',
                            style: TextStyle(color: AppTheme.pewter)),
                      Icon(Icons.chevron_right, color: AppTheme.pewter),
                    ],
                  ),
                  onTap: () => _showUsernameEditSheet(context, provider),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Account Visibility',
                    style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
                  ),
                  trailing: Switch(
                    value: !provider.isPrivate,
                    activeColor: AppTheme.brand,
                    onChanged: (isPublic) {
                      final userId = supabase.auth.currentUser?.id;
                      if (userId != null) {
                        provider.setAccountVisibility(userId,
                            isPrivate: !isPublic);
                      }
                    },
                  ),
                  subtitle: Text(
                    provider.isPrivate ? 'Private' : 'Public',
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppTheme.tobacco),
                  ),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Change password',
                    style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () => context.push('/change-password'),
                ),
                const Divider(color: AppTheme.borderSoft),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Reset onboarding',
                    style: GoogleFonts.nunito(color: AppTheme.ink, fontSize: 15),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppTheme.pewter),
                  onTap: () async {
                    await resetOnboarding();
                  },
                ),
                const Divider(color: AppTheme.borderSoft),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await supabase.auth.signOut();
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.sienna),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
