import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const channelHandle = '@manmandirworld';
const channelUrl = 'https://youtube.com/@manmandirworld';
const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');

void main() => runApp(const MMWApp());

class Song {
  final String id, title, thumbnail, published;
  const Song({required this.id, required this.title, required this.thumbnail, required this.published});
  factory Song.fromJson(Map<String, dynamic> j) {
    final s = j['snippet'] ?? {};
    final t = s['thumbnails'] ?? {};
    final thumb = t['high']?['url'] ?? t['medium']?['url'] ?? t['default']?['url'] ?? '';
    return Song(id: s['resourceId']?['videoId'] ?? j['id']?['videoId'] ?? '', title: s['title'] ?? 'Untitled', thumbnail: thumb, published: s['publishedAt'] ?? '');
  }
}

class MMWApp extends StatelessWidget {
  const MMWApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MMW - Man Mandir World',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF090909),
      colorScheme: const ColorScheme.dark(primary: Color(0xFFD6AD55), secondary: Color(0xFFF2D58A)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF090909), foregroundColor: Color(0xFFF2D58A)),
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  List<Song> songs = [];
  Set<String> favorites = {};
  bool loading = false;
  String error = '';
  Song? current;
  late YoutubePlayerController player;

  @override void initState() {
    super.initState();
    player = YoutubePlayerController.fromVideoId(videoId: '', autoPlay: false, params: const YoutubePlayerParams(showControls: true, showFullscreenButton: true));
    loadFavorites();
    if (apiKey.isNotEmpty) fetchSongs();
  }
  Future<void> loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => favorites = (p.getStringList('favorites') ?? []).toSet());
  }
  Future<void> toggleFavorite(String id) async {
    setState(() { favorites.contains(id) ? favorites.remove(id) : favorites.add(id); });
    final p = await SharedPreferences.getInstance(); await p.setStringList('favorites', favorites.toList());
  }
  Future<void> fetchSongs() async {
    if (apiKey.isEmpty) { setState(() => error = 'YouTube API key abhi configure nahi hui. README mein diye steps follow karein.'); return; }
    setState(() { loading = true; error = ''; });
    try {
      // Resolve channel handle through YouTube Data API, then fetch its uploads playlist.
      final channelUri = Uri.https('www.googleapis.com', '/youtube/v3/channels', {'part':'contentDetails,snippet','forHandle':channelHandle,'key':apiKey});
      final cr = await http.get(channelUri);
      if (cr.statusCode != 200) throw Exception('Channel lookup failed (${cr.statusCode})');
      final cj = jsonDecode(cr.body);
      final items = cj['items'] as List? ?? [];
      if (items.isEmpty) throw Exception('Channel nahi mila. API key aur channel handle check karein.');
      final uploads = items.first['contentDetails']['relatedPlaylists']['uploads'];
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {'part':'snippet','playlistId':uploads,'maxResults':'50','key':apiKey});
      final r = await http.get(uri);
      if (r.statusCode != 200) throw Exception('Songs load nahi hue (${r.statusCode})');
      final data = jsonDecode(r.body);
      final loaded = (data['items'] as List).map((e) => Song.fromJson(e)).where((s) => s.id.isNotEmpty).toList();
      if (mounted) setState(() { songs = loaded; loading = false; });
    } catch (e) { if (mounted) setState(() { error = e.toString(); loading = false; }); }
  }
  void play(Song s) {
    setState(() => current = s);
    player.loadVideoById(videoId: s.id);
  }
  @override void dispose() { player.close(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final shown = songs;
    return Scaffold(
      appBar: AppBar(title: const Row(children: [Icon(Icons.music_note, color: Color(0xFFD6AD55)), SizedBox(width:8), Text('MMW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)), SizedBox(width:8), Text('MAN MANDIR WORLD', style: TextStyle(fontSize: 11, letterSpacing: 1))]), actions: [IconButton(onPressed: fetchSongs, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: fetchSongs, child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors:[Color(0xFF342710),Color(0xFF12100B)]), border: Border.all(color: const Color(0xFF8C6B2F))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('WELCOME TO', style: TextStyle(color: Color(0xFFD6AD55), letterSpacing: 3)), SizedBox(height:6), Text('MAN MANDIR WORLD', style: TextStyle(fontSize:24, fontWeight:FontWeight.bold)), SizedBox(height:6), Text('Your music. Your world.', style: TextStyle(color: Colors.white70))])),
        const SizedBox(height:22),
        const Text('ALL SONGS', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold, letterSpacing:2)),
        const SizedBox(height:10),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child:CircularProgressIndicator())),
        if (error.isNotEmpty) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white10,borderRadius:BorderRadius.circular(12)), child: Text(error, style: const TextStyle(color: Colors.orangeAccent))),
        if (!loading && songs.isEmpty && error.isEmpty) const Text('Songs yahan automatically dikhne lagenge. YouTube API key configure karein.', style: TextStyle(color:Colors.white70)),
        for (final s in shown) Card(color: const Color(0xFF171717), child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: ClipRRect(borderRadius:BorderRadius.circular(8), child: Image.network(s.thumbnail, width:76, height:56, fit:BoxFit.cover, errorBuilder:(_,__,___)=>const SizedBox(width:76,child:Icon(Icons.music_note)))),
          title: Text(s.title, maxLines:2, overflow:TextOverflow.ellipsis),
          subtitle: const Text('Man Mandir World', style:TextStyle(color:Color(0xFFD6AD55))),
          trailing: IconButton(icon: Icon(favorites.contains(s.id)?Icons.favorite:Icons.favorite_border, color:const Color(0xFFD6AD55)), onPressed:()=>toggleFavorite(s.id)),
          onTap:()=>play(s),
        )),
        const SizedBox(height:14),
        if (current != null) ...[
          Text('NOW PLAYING · ${current!.title}', maxLines:1, overflow:TextOverflow.ellipsis, style:const TextStyle(color:Color(0xFFD6AD55))),
          const SizedBox(height:8),
          YoutubePlayer(controller:player, aspectRatio:16/9),
        ],
        const SizedBox(height:20),
        OutlinedButton.icon(onPressed:()=>launchChannel(context), icon:const Icon(Icons.subscriptions), label:const Text('VISIT YOUTUBE CHANNEL')),
      ])),
    );
  }
}

void launchChannel(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Channel: https://youtube.com/@manmandirworld')));
}
