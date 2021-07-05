import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_list_pagination/model/passenger_data.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite List Pagination',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _title = "Infinite List Pagination";

  late int totalPages;

  /// ပထမဆုံး ရရှိမယ့်စာမျက်နှာကို ကြိုတင် သတ်မှတ်ထားခြင်း
  int currentPage = 1;

  /// ရလာမယ့် ဒေတာတွေကို List အဖြစ်ပြောင်းသုံးဖို့ ကြေညာထားခြင်း
  List<Passenger> passengers = [];

  /// Page ကို Refresh လုပ်စေနိုင်ဖို့
  final RefreshController refreshController =
      RefreshController(initialRefresh: true);

  /// Api အတွက် ဒေတာယူဖို့အတွက် ဖန်ရှင်တစ်ခုတည်ဆောက်ခြင်း
  Future<bool> getPassengerData({bool isRefresh = false}) async {
    /// အကယ်၍ စာမျက်နှာက Refresh ဖြစ်ခဲ့မယ်ဆိုရင်
    /// လက်ရှိစာမျက်နှာကို ၁ ကနေ ပြပေးရန်
    if (isRefresh) {
      currentPage = 1;
    } else {
      if (currentPage >= totalPages) {
        refreshController.loadNoData();
        return false;
      }
    }

    final Uri uri = Uri.parse(
        "https://api.instantwebtools.net/v1/passenger?page=$currentPage&size=10");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      /// အကယ်၍ ဒေတာရခဲ့ရင် Run မည်ဖြစ်သည်။
      /// Model ထဲမှ ရလာသော ဒေတာဖြစ်သည်။
      final result = passengersDataFromJson(response.body);

      /// အပေါ်က List<Passenger> ထဲသို့ ပေးပို့ခြင်း
      if (isRefresh) {
        passengers = result.data;
      } else {
        passengers.addAll(result.data);
      }

      /// လက်ရှိစာမျက်နှာကို ထပ်တိုးခြင်း
      currentPage++;

      /// ရောက်နေတဲ့စာမျက်နှာပေါင်းကို သိရှိရန်
      totalPages = result.totalPages;

      /// Debug အတွက်
      print(response.body);

      setState(() {});

      return true;
    } else {
      /// ဒေတာမရခဲ့ရင် ဆက်မ Run ပါ။
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SmartRefresher(
        /// အောက်က Controller ကို ကြေညာဖို့မမေ့နဲ့
        controller: refreshController,
        enablePullUp: true,

        /// ဒေတာမကျသေးရင် Refresh လုပ်မယ်
        /// ဒေတာရသွားရင် Refresh ကို ပြန်ပိတ်မယ်
        onRefresh: () async {
          final result = await getPassengerData(isRefresh: true);
          if (result) {
            refreshController.refreshCompleted();
          } else {
            refreshController.refreshFailed();
          }
        },

        /// Pagination အတွက်
        onLoading: () async {
          final result = await getPassengerData(isRefresh: true);
          if (result) {
            refreshController.loadComplete();
          } else {
            refreshController.loadFailed();
          }
        },
        child: ListView.separated(
          itemBuilder: (context, index) {
            final passenger = passengers[index];

            return ListTile(
              title: Text(passenger.name),
              subtitle: Text(passenger.airline.country),
              trailing: Text(passenger.airline.name),
            );
          },
          separatorBuilder: (context, index) => Divider(),
          itemCount: passengers.length,
        ),
      ),
    );
  }
}
