import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/theme/theme_cubit.dart';
import '../widgets/custom_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Select your preferred theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Select Theme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<AppTheme>(
                          title: const Text('Light Theme'),
                          value: AppTheme.light,
                          groupValue: context.read<ThemeCubit>().state,
                          onChanged: (value) {
                            context.read<ThemeCubit>().toggleTheme();
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<AppTheme>(
                          title: const Text('Dark Theme'),
                          value: AppTheme.dark,
                          groupValue: context.read<ThemeCubit>().state,
                          onChanged: (value) {
                            context.read<ThemeCubit>().toggleTheme();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          ListTile(
            title: const Text('About'),
            subtitle: const Text('Learn more about the app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context,
              );
            },
          ),

          // Add more settings options as needed
        ],
      ),
    );
  }

  void showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/applogo.png',
                height: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'QRCode Generator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                  "Simplify information sharing and access with QR Generator - the effortless way to generate and scan QR codes."),
              const SizedBox(height: 16),
              const Text(
                'Developer:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Saman KC'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
