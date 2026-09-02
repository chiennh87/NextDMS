// ============================================================================
// Outlet Drafts Screen - Quan ly cac outlet draft offline
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/outlet_onboarding_bloc.dart';
import '../bloc/outlet_onboarding_event.dart';
import '../bloc/outlet_onboarding_state.dart';
import '../widgets/sync_status_banner.dart';

class OutletDraftsScreen extends StatefulWidget {
  const OutletDraftsScreen({super.key});

  @override
  State<OutletDraftsScreen> createState() => _OutletDraftsScreenState();
}

class _OutletDraftsScreenState extends State<OutletDraftsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OutletOnboardingBloc>().add(const OutletDraftsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outlet Drafts (Offline)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Dong bo tat ca',
            onPressed: () => context.read<OutletOnboardingBloc>().add(const OutletSyncRequested()),
          ),
        ],
      ),
      body: BlocBuilder<OutletOnboardingBloc, OutletOnboardingState>(
        builder: (ctx, state) {
          if (state is OutletDraftsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OutletDraftsLoaded) {
            if (state.drafts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('Khong co draft nao'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/create-outlet'),
                      icon: const Icon(Icons.add),
                      label: const Text('Tao outlet moi'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.drafts.length,
              itemBuilder: (ctx, i) {
                final draft = state.drafts[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(draft.name ?? '(chua co ten)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (draft.phone != null) Text('SDT: ${draft.phone}'),
                        Text('LocalID: ${draft.localId.substring(0, 8)}...'),
                      ],
                    ),
                    trailing: SyncStatusBadge(syncStatus: draft.syncStatus),
                    onTap: () => Navigator.pushNamed(context, '/create-outlet'),
                  ),
                );
              },
            );
          }
          if (state is OutletOnboardingFailure) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}