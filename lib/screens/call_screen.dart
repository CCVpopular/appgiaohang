import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isOutgoing;
  final VoidCallback? onCallEnded; // Add callback
  final VoidCallback? onCallRejected; // Add rejection callback

  const CallScreen({
    required this.channelName,
    required this.token,
    this.isOutgoing = true,
    this.onCallEnded,
    this.onCallRejected,
  });

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _isInCall = false;
  int? _remoteUid; // Add this to track remote user

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      print('Initializing call with:');
      print('Channel: ${widget.channelName}');
      
      // Validate token and channel name first
      if (widget.channelName.isEmpty || widget.token.isEmpty) {
        throw Exception('Invalid channel name or token');
      }

      await _callService.initializeAgora();

      _callService.engine?.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("Successfully joined channel: ${connection.channelId}");
          if (mounted) {
            setState(() => _isInCall = true);
          }
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          print("Remote user $remoteUid joined");
          if (mounted) {
            setState(() => _remoteUid = remoteUid);
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          print("Remote user $remoteUid left: $reason");
          if (mounted) {
            setState(() => _remoteUid = null);
            _endCall();
          }
        },
        onConnectionStateChanged: (connection, state, reason) {
          print("Connection state changed to $state: $reason");
          if (state == ConnectionStateType.connectionStateFailed) {
            _handleError("Connection failed: ${reason.toString()}");
          }
        },
        onError: (err, msg) {
          print("Error occurred: $err - $msg");
          _handleError(msg);
        },
      ));

      await _callService.joinCall(widget.channelName, widget.token);
      
    } catch (e) {
      print("Call initialization error: $e");
      _handleError(e.toString());
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    
    print("Error occurred: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
    
    _endCall();
  }

  Future<void> _endCall() async {
    await _callService.leaveCall();
    if (widget.onCallEnded != null) {
      widget.onCallEnded!();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleCallRejected() {
    if (widget.onCallRejected != null) {
      widget.onCallRejected!();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main view (remote user)
            if (_isInCall) ...[
              if (_remoteUid != null)
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _callService.engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                    useFlutterTexture: true, // Add this line
                    useAndroidSurfaceView: true, // Add this line
                  ),
                ),
              // Local user view (smaller)
              Positioned(
                top: 10,
                right: 10,
                width: 120,
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _callService.engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: _callService.isMicOn ? Icons.mic : Icons.mic_off,
                    onPressed: () {
                      _callService.toggleMicrophone();
                      setState(() {});
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    onPressed: _endCall, // Use the new method
                  ),
                  _buildControlButton(
                    icon: _callService.isCameraOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    onPressed: () {
                      _callService.toggleCamera();
                      setState(() {});
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.switch_camera,
                    onPressed: () {
                      _callService.switchCamera();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return CircleAvatar(
      backgroundColor: Colors.black54,
      radius: 25,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}