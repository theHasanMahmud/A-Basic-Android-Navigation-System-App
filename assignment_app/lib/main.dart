import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const AssignmentApp());
}

class AssignmentApp extends StatelessWidget {
  const AssignmentApp({super.key});

  static const Color primaryColor = CupertinoColors.systemPurple;

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'CSE489 Assignment 2',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.white,
      ),
      home: HomeScreen(),
    );
  }
}

enum DrawerSection { broadcast, imageScale, video, audio }

extension on DrawerSection {
  String get label {
    switch (this) {
      case DrawerSection.broadcast:
        return 'Broadcast Receiver';
      case DrawerSection.imageScale:
        return 'Image Scale';
      case DrawerSection.video:
        return 'Video Player';
      case DrawerSection.audio:
        return 'Audio Player';
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DrawerSection _selectedSection = DrawerSection.broadcast;

  void _selectSection(DrawerSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  Future<void> _showMenuSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Navigate to'),
        actions: DrawerSection.values
            .map(
              (section) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _selectSection(section);
                },
                isDefaultAction: section == _selectedSection,
                child: Text(section.label),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          isDefaultAction: false,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String get _currentTitle {
    switch (_selectedSection) {
      case DrawerSection.broadcast:
        return 'Broadcast Receiver Flow';
      case DrawerSection.imageScale:
        return 'Image Scale';
      case DrawerSection.video:
        return 'Video Player';
      case DrawerSection.audio:
        return 'Audio Player';
    }
  }

  Widget _buildSection() {
    switch (_selectedSection) {
      case DrawerSection.broadcast:
        return const BroadcastScreen();
      case DrawerSection.imageScale:
        return const ImageScaleScreen();
      case DrawerSection.video:
        return const VideoPlayerScreen();
      case DrawerSection.audio:
        return const AudioPlayerScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_currentTitle),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showMenuSheet,
          child: const Icon(CupertinoIcons.bars),
        ),
      ),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildSection(),
        ),
      ),
    );
  }
}

enum BroadcastOption { custom, battery }

class CustomBroadcastService {
  CustomBroadcastService();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void send(String message) {
    _controller.add(message);
  }

  void dispose() {
    _controller.close();
  }
}

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  BroadcastOption? _selectedOption;
  final CustomBroadcastService _service = CustomBroadcastService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _continueFlow() {
    if (_selectedOption == null) {
      _showToast('Please select a broadcast option.');
      return;
    }

    switch (_selectedOption!) {
      case BroadcastOption.custom:
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) => BroadcastInputPage(service: _service),
          ),
        );
        break;
      case BroadcastOption.battery:
        Navigator.of(
          context,
        ).push(CupertinoPageRoute(builder: (_) => const BatteryStatusPage()));
        break;
    }
  }

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 32,
        left: 24,
        right: 24,
        child: _CupertinoToast(message: message),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(
      const Duration(seconds: 2),
    ).then((_) => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'First Activity',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select which broadcast operation to demonstrate using the Cupertino '
            'style controls below.',
          ),
          const SizedBox(height: 24),
          CupertinoSlidingSegmentedControl<BroadcastOption>(
            groupValue: _selectedOption,
            thumbColor: CupertinoColors.white,
            children: const {
              BroadcastOption.custom: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text('Custom broadcast'),
              ),
              BroadcastOption.battery: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text('Battery receiver'),
              ),
            },
            onValueChanged: (value) {
              setState(() {
                _selectedOption = value;
              });
            },
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton.filled(
              onPressed: _continueFlow,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class BroadcastInputPage extends StatefulWidget {
  const BroadcastInputPage({super.key, required this.service});

  final CustomBroadcastService service;

  @override
  State<BroadcastInputPage> createState() => _BroadcastInputPageState();
}

class _BroadcastInputPageState extends State<BroadcastInputPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showValidationToast();
      return;
    }
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CustomBroadcastReceiverPage(
          service: widget.service,
          message: message,
        ),
      ),
    );
  }

  void _showValidationToast() {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => const Positioned(
        bottom: 32,
        left: 24,
        right: 24,
        child: _CupertinoToast(message: 'Please enter a message to send.'),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(
      const Duration(seconds: 2),
    ).then((_) => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Custom Broadcast Input'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Second Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter a message below. The next activity will simulate receiving '
                'this broadcast.',
              ),
              const SizedBox(height: 24),
              CupertinoTextField(
                controller: _controller,
                maxLines: 5,
                placeholder: 'Message to broadcast',
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton.filled(
                  onPressed: _handleSend,
                  child: const Text('Send to third activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomBroadcastReceiverPage extends StatefulWidget {
  const CustomBroadcastReceiverPage({
    super.key,
    required this.service,
    required this.message,
  });

  final CustomBroadcastService service;
  final String message;

  @override
  State<CustomBroadcastReceiverPage> createState() =>
      _CustomBroadcastReceiverPageState();
}

class _CustomBroadcastReceiverPageState
    extends State<CustomBroadcastReceiverPage> {
  StreamSubscription<String>? _subscription;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _subscription = widget.service.stream.listen((incoming) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastMessage = incoming;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.service.send(widget.message);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Custom Broadcast Receiver'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Third Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Received broadcast message:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _lastMessage ?? 'Listening for broadcasts...',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  CupertinoButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Send another message'),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.pop();
                    },
                    child: const Text('Back to broadcast menu'),
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

class BatteryStatusPage extends StatefulWidget {
  const BatteryStatusPage({super.key});

  @override
  State<BatteryStatusPage> createState() => _BatteryStatusPageState();
}

class _BatteryStatusPageState extends State<BatteryStatusPage> {
  final Battery _battery = Battery();
  int? _batteryLevel;
  BatteryState? _batteryState;
  String? _error;
  StreamSubscription<BatteryState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _fetchBatteryLevel();
    _stateSubscription = _battery.onBatteryStateChanged.listen((state) {
      setState(() {
        _batteryState = state;
      });
      _fetchBatteryLevel();
    });
  }

  Future<void> _fetchBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (!mounted) {
        return;
      }
      setState(() {
        _batteryLevel = level;
        _error = null;
      });
    } catch (err) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to read battery level: $err';
      });
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (_batteryState) {
      BatteryState.charging => 'Charging',
      BatteryState.discharging => 'Discharging',
      BatteryState.full => 'Full',
      BatteryState.connectedNotCharging => 'Connected (not charging)',
      BatteryState.unknown || null => 'Unknown',
    };

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Battery Broadcast Receiver'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Second Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Battery details',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ] else if (_batteryLevel == null) ...[
                        const Center(child: CupertinoActivityIndicator()),
                      ] else ...[
                        Text(
                          'Level: $_batteryLevel%',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text('Status: $statusLabel'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton.filled(
                onPressed: _fetchBatteryLevel,
                child: const Text('Refresh level'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageScaleScreen extends StatefulWidget {
  const ImageScaleScreen({super.key});

  static const String _imageUrl =
      'https://picsum.photos/id/1025/1200/800'; // Stable image for demo

  @override
  State<ImageScaleScreen> createState() => _ImageScaleScreenState();
}

class _ImageScaleScreenState extends State<ImageScaleScreen> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _controller.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Use a pinch gesture (or CTRL + scroll) to zoom and two fingers to pan.',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                transformationController: _controller,
                minScale: 0.5,
                maxScale: 4,
                panEnabled: true,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Image.network(
                        ImageScaleScreen._imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Failed to load image'),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              onPressed: _reset,
              child: const Text('Reset zoom'),
            ),
          ),
        ),
      ],
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      ),
    );
    _initialize = _controller.initialize().then((_) {
      _controller.setLooping(true);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller
      ..setLooping(false)
      ..dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CupertinoActivityIndicator());
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: _togglePlayback,
                      child: Text(
                        _controller.value.isPlaying ? 'Pause' : 'Play',
                      ),
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
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  bool _isLoading = false;
  String? _playbackError;
  StreamSubscription<PlayerState>? _stateSub;

  static const String _assetPath = 'audio/sample.wav';

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playerState = state;
        _isLoading = false;
        if (state == PlayerState.playing) {
          _playbackError = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    setState(() {
      _isLoading = true;
      _playbackError = null;
    });
    try {
      await _player.play(AssetSource(_assetPath));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _playbackError =
            'Audio playback is not supported on this platform or emulator.';
      });
    }
  }

  Future<void> _pause() async {
    await _player.pause();
  }

  Future<void> _stop() async {
    await _player.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Audio Playback Demo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plays a bundled sample tone so the demo works offline.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_isLoading) const CupertinoActivityIndicator(),
          if (_playbackError != null) ...[
            const SizedBox(height: 12),
            Text(
              _playbackError!,
              style: const TextStyle(color: CupertinoColors.systemRed),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              CupertinoButton.filled(
                onPressed: _playerState == PlayerState.playing ? null : _play,
                child: const Text('Play'),
              ),
              CupertinoButton(
                onPressed: _playerState == PlayerState.playing ? _pause : null,
                child: const Text('Pause'),
              ),
              CupertinoButton(
                onPressed: _playerState == PlayerState.stopped ? null : _stop,
                child: const Text('Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CupertinoToast extends StatelessWidget {
  const _CupertinoToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC000000),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.white),
          ),
        ),
      ),
    );
  }
}
