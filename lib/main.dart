import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "One Item Store",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ItemScreen(),
    );
  }
}

class ItemScreen extends StatefulWidget {
  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  String serverAddress = "https://oneitem.notifyme.tk";

  bool haveData = false;
  double imagePercentageOfScreen = 53;
  String name;
  String buyLink;
  int hartCount;
  bool addHart = false;
  int imageSelected = 0;
  String description;
  double price;
  ScrollController imageScrollControler;
  List<dynamic> imageLinks;

  int get imageCount {
    return imageLinks.length;
  }

  void updateLikes() async {
    var response = await http.get(Uri.parse(this.serverAddress + "/likes"));
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        hartCount = json["likes"];
        prefs.setInt("likes_count", hartCount);
      });
    }
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.clear();
    int day = prefs.getInt("day");
    if (day == null || DateTime.now().day != day) {
      prefs.clear();
      prefs.setBool("like", false);
      await loadFromServer();
      prefs.setInt("day", DateTime.now().day);
      return;
    }
    name = prefs.getString("name");
    print("name $name");
    buyLink = prefs.getString("buy_link");
    print("buy link $buyLink");
    hartCount = prefs.getInt("likes_count");
    print("hartCount $hartCount");
    updateLikes();
    imageLinks = prefs.getStringList("photos_links");
    print("imageLinks $imageLinks");
    description = prefs.getString("description");
    print("description $description");
    price = prefs.getDouble("price");
    print("price $price");
    addHart = prefs.getBool("like") ?? false;
    setState(() {
      haveData = true;
    });
  }

  Future<void> loadFromServer() async {
    if (haveData) {
      return;
    }
    var url = Uri.parse(this.serverAddress + "/best_product");
    var response = await http.get(url).timeout(Duration(seconds: 5));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        var json = jsonDecode(response.body);
        List<String> photosLinks = json["photos_links"].map<String>((link) {
          String l = link;
          return l;
        }).toList();
        prefs.setInt("likes_count", json['likes_count']);
        hartCount = json["likes_count"];
        prefs.setStringList("photos_links", photosLinks);
        imageLinks = photosLinks;
        prefs.setString("description", json["description"]);
        description = json["description"];
        prefs.setDouble("price", json["price"]);
        price = json["price"];
        prefs.setString("name", json["name"]);
        name = json["name"];
        prefs.setString("buy_link", json["buy_link"]);
        buyLink = json["buy_link"];
        addHart = prefs.getBool("like") ?? false;
        haveData = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    imageScrollControler = ScrollController()
      ..addListener(() {
        double imageOffset =
            imageScrollControler.offset / MediaQuery.of(context).size.width;
        if (imageOffset != imageSelected) {
          setState(() {
            imageSelected = imageOffset.round();
          });
        }
      });
  }

  @override
  void dispose() {
    imageScrollControler
        .dispose(); // it is a good practice to dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (haveData) {
      return Container(
        color: Colors.white,
        child: Stack(
          children: [
            ProductTop(
                imagePercentageOfScreen: imagePercentageOfScreen,
                scrollController: imageScrollControler,
                imageCount: imageCount,
                imageSelected: imageSelected,
                imageLinks: imageLinks,
                name: name),
            ProductBottom(
              imagePercentageOfScreen: imagePercentageOfScreen,
              hartCount: hartCount,
              addHart: addHart,
              loveIt: loveIt,
              description: description,
              price: price,
              buyLink: buyLink,
            ),
          ],
        ),
      );
    } else {
      loadData();
      return Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  void loveIt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (!addHart) {
        addHart = true;
        hartCount += 1;
        http.post(Uri.parse(this.serverAddress + "/like")).whenComplete(() {
          prefs.setBool("like", true);
        });
      }
    });
  }
}

class ProductTop extends StatelessWidget {
  const ProductTop({
    Key key,
    @required this.scrollController,
    @required this.imagePercentageOfScreen,
    @required this.imageSelected,
    @required this.imageCount,
    @required this.imageLinks,
    @required this.name,
  }) : super(key: key);

  final double imagePercentageOfScreen;
  final ScrollController scrollController;
  final int imageSelected;
  final int imageCount;
  final List<dynamic> imageLinks;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height / 100 * imagePercentageOfScreen,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          productImages(context),
          /*productName(context),*/ imageDots()
        ],
      ),
    );
  }

  Widget productImages(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      itemExtent: MediaQuery.of(context).size.width,
      itemCount: imageCount,
      physics: PageScrollPhysics(),
      itemBuilder: (context, index) => InteractiveViewer(
        child:
            CachedNetworkImage(imageUrl: imageLinks[index], fit: BoxFit.fill),
      ),
    );
  }

  Container imageDots() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < imageCount; i++) imageDot(i),
          ],
        ),
      ),
    );
  }

  Widget imageDot(int dotNumber) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: dotNumber == this.imageSelected ? 20 : 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(50),
        ),
        color: Colors.white,
      ),
    );
  }

  Row productName(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          margin: EdgeInsets.only(top: 20),
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Text(
            "$name",
            style: Theme.of(context)
                .textTheme
                .headline4
                .copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class ProductBottom extends StatelessWidget {
  ProductBottom({
    Key key,
    @required this.imagePercentageOfScreen,
    @required this.hartCount,
    @required this.addHart,
    @required this.loveIt,
    @required this.price,
    @required this.description,
    @required this.buyLink,
  }) : super(key: key);
  final double imagePercentageOfScreen;
  final int hartCount;
  final bool addHart;
  final Function loveIt;
  final double price;
  final String description;
  final String buyLink;

  @override
  Widget build(BuildContext context) {
    return productInfo(context);
  }

  Widget productInfo(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height / 100 * imagePercentageOfScreen -
          20,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height /
            100 *
            (100 - imagePercentageOfScreen),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        child: Container(
          margin:
              const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [hartCounter(context), priceWidget(context)],
                  ),
                  SizedBox(height: 30),
                  productDescription(context),
                ],
              ),
              buyButton(context),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector buyButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await canLaunch(buyLink)
            ? await launch(buyLink)
            : throw 'Could not launch $buyLink';
      },
      child: Container(
        //margin: EdgeInsets.only(bottom: 10),
        alignment: Alignment.center,
        height: 50,
        width: 200,
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 1.0), //(x,y)
                blurRadius: 10.0,
              ),
            ],
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Text(
          "I Want That!",
          style: Theme.of(context)
              .textTheme
              .headline5
              .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Container productDescription(BuildContext context) {
    int descriptionMaxLength = 230;
    return Container(
      alignment: Alignment.centerLeft,
      width: MediaQuery.of(context).size.width / 100 * 73,
      child: Text(
        description.length > descriptionMaxLength
            ? description.substring(0, descriptionMaxLength) + "..."
            : description,
        style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 18),
      ),
    );
  }

  Text priceWidget(BuildContext context) {
    return Text(
      "$price\$",
      style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 30),
    );
  }

  Widget hartCounter(BuildContext context) {
    return GestureDetector(
      onTap: loveIt,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 50),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(0.0, 1.0), //(x,y)
                blurRadius: addHart ? 10 : 0,
              ),
            ],
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(13))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Text(
                "$hartCount",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(color: Colors.white, fontSize: 22),
              ),
              SizedBox(width: 5),
              Icon(
                Icons.favorite,
                color: addHart ? Colors.red : Colors.white,
              )
            ],
          ),
        ),
      ),
    );
  }
}
