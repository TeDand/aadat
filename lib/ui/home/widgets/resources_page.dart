// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  static const _resources = [
    _Resource(
      title: 'Atomic Habits',
      author: 'James Clear',
      description:
          'Tiny changes, remarkable results. The definitive guide to building good habits and breaking bad ones.',
      tag: 'book',
      url: 'https://www.goodreads.com/book/show/40121378-atomic-habits',
    ),
    _Resource(
      title: '75 Medium Challenge',
      author: 'Marathon Handbook',
      description:
          'A gentler take on 75 Hard — 75 days of consistent healthy habits without burning out.',
      tag: 'challenge',
      url: 'https://marathonhandbook.com/75-medium-challenge/',
    ),
    _Resource(
      title: 'Tiny Habits',
      author: 'BJ Fogg',
      description:
          'Small habits, big change. Learn to wire new behaviours into your life using motivation and ability.',
      tag: 'book',
      url:
          'https://www.penguin.co.uk/books/438937/tiny-habits-by-bj-fogg/9780753553244',
    ),
    _Resource(
      title: 'Better Than Before',
      author: 'Gretchen Rubin',
      description:
          'What do you know about yourself? Rubin explores how to use your personality to build habits that stick.',
      tag: 'book',
      url: 'https://www.goodreads.com/en/book/show/22889767-better-than-before',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Resources'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(
            'Reading list',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'A curated handful of reads and challenges to help you build better habits.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          for (final resource in _resources) ...[
            _ResourceCard(resource: resource),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});

  final _Resource resource;

  static const _tagColors = {
    'book': Color(0xFF2563EB),
    'challenge': Color(0xFFEA580C),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tagColor = _tagColors[resource.tag] ?? scheme.primary;

    return Card(
      child: InkWell(
        onTap: () {
          if (kIsWeb) {
            html.window.open(resource.url, '_blank');
          } else {
            launchUrl(Uri.parse(resource.url), mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      resource.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Tag(label: resource.tag, color: tagColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                resource.author,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                resource.description,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      resource.url,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tap to open',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Resource {
  const _Resource({
    required this.title,
    required this.author,
    required this.description,
    required this.tag,
    required this.url,
  });

  final String title;
  final String author;
  final String description;
  final String tag;
  final String url;
}
