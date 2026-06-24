import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/profile_provider.dart';
import '../../core/auth/profile_service.dart';
import '../../core/models/user_model.dart';
import '../../shared/widgets/app_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefillFromGoogleUser();
  }

  void _prefillFromGoogleUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final metadataName = user.userMetadata?['full_name'] as String?;
    final emailPrefix = user.email?.split('@').first;
    _nameController.text = metadataName ?? emailPrefix ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  String get _avatarPreviewUrl {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '';
    return UserModel(
      id: '',
      name: name,
      upiId: '',
      createdAt: DateTime.now(),
    ).avatarUrl.replaceFirst('/svg?', '/png?');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save a profile')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ProfileService.upsertProfile(
        userId: userId,
        name: _nameController.text,
        upiId: _upiController.text,
      );
      ref.invalidate(currentProfileProvider);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: _avatarPreviewUrl.isNotEmpty
                        ? NetworkImage(_avatarPreviewUrl)
                        : null,
                    child: _avatarPreviewUrl.isEmpty
                        ? Icon(
                            Icons.person_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avatar generated from your display name',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    hintText: 'Ananya',
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI VPA',
                    hintText: 'yourname@ybl',
                    helperText: 'Used when friends pay you back via UPI',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your UPI ID';
                    }
                    if (!value.contains('@')) {
                      return 'UPI ID should look like name@bank';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save and continue',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
