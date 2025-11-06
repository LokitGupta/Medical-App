import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/utils/app_colors.dart';
import 'package:medical_app/widgets/custom_button.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String doctorName;
  final String? doctorAvatar;
  final String appointmentId;

  const VideoCallScreen({
    Key? key,
    required this.doctorName,
    this.doctorAvatar,
    required this.appointmentId,
  }) : super(key: key);

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _isCallStarted = false;
  
  @override
  void initState() {
    super.initState();
    // Simulate connection delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isCallStarted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video view (doctor)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: _isConnecting
                ? _buildConnectingView()
                : _isCallStarted
                    ? _buildCallView()
                    : _buildEndedCallView(),
          ),
          
          // Top bar with doctor info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                    backgroundImage: widget.doctorAvatar != null
                        ? NetworkImage(widget.doctorAvatar!)
                        : null,
                    child: widget.doctorAvatar == null
                        ? Text(
                            widget.doctorName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.doctorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _isConnecting
                            ? 'Connecting...'
                            : _isCallStarted
                                ? 'In call'
                                : 'Call ended',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _isMicMuted
                        ? Icons.mic_off
                        : Icons.mic,
                    label: _isMicMuted ? 'Unmute' : 'Mute',
                    onPressed: () {
                      setState(() {
                        _isMicMuted = !_isMicMuted;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: _isCameraOff
                        ? Icons.videocam_off
                        : Icons.videocam,
                    label: _isCameraOff ? 'Camera On' : 'Camera Off',
                    onPressed: () {
                      setState(() {
                        _isCameraOff = !_isCameraOff;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: _isSpeakerOn
                        ? Icons.volume_up
                        : Icons.volume_off,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onPressed: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      setState(() {
                        _isCallStarted = false;
                      });
                      
                      // End call after a short delay
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pop(context);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Connecting to ${widget.doctorName}...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we establish a secure connection',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCallView() {
    // This would be replaced with actual video stream
    return Stack(
      children: [
        // Doctor's video (full screen)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[800],
          child: Center(
            child: Icon(
              Icons.person,
              size: 120,
              color: Colors.grey[600],
            ),
          ),
        ),
        
        // Patient's video (small overlay)
        Positioned(
          right: 16,
          top: 100,
          child: Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: _isCameraOff
                ? const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white,
                      size: 32,
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
          ),
        ),
        
        // Call duration
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '00:00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndedCallView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.call_end,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Call Ended',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your call with ${widget.doctorName} has ended',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            onPressed: () => Navigator.pop(context),
            text: 'Return to App',
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}