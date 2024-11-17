import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './question_card.dart';

class QuestionsList extends ConsumerWidget {
  final String collectionName;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  const QuestionsList({
    super.key,
    required this.collectionName,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No data found"));
          }

          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return QuestionCard(
                doc: snapshot.data!.docs[index],
                collectionName: collectionName,
                onRefresh: onRefresh,
              );
            },
          );
        },
      ),
    );
  }
}