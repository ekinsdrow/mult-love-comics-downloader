import 'dart:io';

import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

Future<void> main(List<String> arguments) async {
  final urls = [
    'https://simpsons.fox-fan.tv/comixs.php?id=1',
  ];


  for (var i = 0; i < urls.length; i++) {
    print('GET Comics list page ${i + 1}/${urls.length}');
    final uri = urls[i];

    print("Comics list page url - $uri");

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      final doc = parse(response.body);
      final comics = doc.getElementsByClassName('smallSeason');

      final documentDirectory =
          'output/${doc.getElementsByClassName('numberSeason').first.children.first.children.first.innerHtml}';

      print("Count of comics ${comics.length}");


      for (int i = 0; i < comics.length;i++) {
        await getComics(
          comics[i].children.first.attributes['href']!,
          documentDirectory,
          (i+1).toString(),
        );
      }
    } else {
      print("Error with comics list page");
    }
  }
}

Future<void> getComics(
  String url,
  String documentDir,
  String index,
) async {
  final uri = 'https://simpsons.fox-fan.tv/$url&str=1'.replaceAll('#mark', '');

  print('GET comics $uri');
  final comics = await http.get(Uri.parse(uri));

  if (comics.statusCode == 200) {
    final doc = parse(comics.body);

    final comicsPages = doc.getElementById('navComix')!;

    final documentDirectory = documentDir + '/$index';

    final firstPage = await getPage(uri, documentDirectory, '1');

    for (var i = 1; i < comicsPages.children.length; i++) {
      final page = await getPage(
        'https://simpsons.fox-fan.tv/' +
            comicsPages.children[i].attributes['href']!,
        documentDirectory,
        '${i + 1}',
      );
    }
  } else {
    print('Error with comics');
  }

  print('-------------------------------------------');
}

Future<void> getPage(
  String url,
  String dir,
  String index,
) async {
  print('GET PAGE $url');

  final page = await http.get(Uri.parse(url));

  if (page.statusCode == 200) {
    final doc = parse(page.body);

    final imageElement = doc.getElementsByTagName('img')[3];
    final image = await http.get(
      Uri.parse(
          'https://simpsons.fox-fan.tv/${imageElement.attributes['src']!}'),
    );

   if(image.statusCode == 200){
      final file = File(
      join(dir, '$index.jpg'),
    );

    await file.create(recursive: true);

    file.writeAsBytesSync(image.bodyBytes);
   }else{
    print('Error with image');

   }
  } else {
    print('Error with page');
  }
}
