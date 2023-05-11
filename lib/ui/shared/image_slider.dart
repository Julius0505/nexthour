import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_translate/flutter_translate.dart';
import '/common/apipath.dart';
import '/common/global.dart';
import '/common/route_paths.dart';
import '/common/styles.dart';
import '/models/datum.dart';
import '/providers/movie_tv_provider.dart';
import '/providers/slider_provider.dart';
import '/ui/screens/video_detail_screen.dart';
import 'package:provider/provider.dart';

class ImageSlider extends StatefulWidget {
  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  List<Datum>? showsMoviesList;

  Widget imageSlider() {
    final slider = Provider.of<SliderProvider>(context, listen: false);
    final movieList =
        Provider.of<MovieTVProvider>(context, listen: false).moviesList;
    final tvList =
        Provider.of<MovieTVProvider>(context, listen: false).tvSeriesList;
    return Stack(children: <Widget>[
      Container(
        child: slider.sliderModel!.slider!.length == 0
            ? SizedBox.shrink()
            : Swiper(
                scrollDirection: Axis.horizontal,
                loop: true,
                autoplay: true,
                duration: 500,
                autoplayDelay: 10000,
                autoplayDisableOnInteraction: true,
                itemCount: slider.sliderModel == null
                    ? 0
                    : slider.sliderModel!.slider!.length,
                itemBuilder: (BuildContext context, int index) {
                  var linkedTo =
                      slider.sliderModel!.slider![index].tvSeriesId != null
                          ? "shows/"
                          : slider.sliderModel!.slider![index].movieId != null
                              ? "movies/"
                              : "";

                  if (slider.sliderModel!.slider!.isEmpty) {
                    return SizedBox.shrink();
                  } else {
                    if (slider.sliderModel!.slider![index].slideImage == null) {
                      return SizedBox.shrink();
                    } else {
                      List<Datum> x = [];

                      if (slider.sliderModel!.slider![index].movieId != null) {
                        x = List.from(movieList.where((item) =>
                            "${item.id}" ==
                            "${slider.sliderModel!.slider![index].movieId}"));
                      } else {
                        x = List.from(tvList.where((item) =>
                            "${item.id}" ==
                            "${slider.sliderModel!.slider![index].tvSeriesId}"));
                      }

                      return InkWell(
                        child: Container(
                          padding: const EdgeInsets.only(
                              top: 0.0, bottom: 0.0, left: 0.0, right: 0.0),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage("${APIData.appSlider}" +
                                  "$linkedTo" +
                                  "${slider.sliderModel!.slider![index].slideImage}"),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                Image.asset(
                                  "assets/placeholder_box.jpg",
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  gradient: LinearGradient(
                                    begin: FractionalOffset.topCenter,
                                    end: FractionalOffset.bottomCenter,
                                    colors: [
                                      Theme.of(context).primaryColorDark,
                                      Colors.transparent,
                                      Colors.transparent,
                                      Theme.of(context).primaryColorDark,
                                    ],
                                    stops: [0.02, 0.4, 0.6, 1.0],
                                  ),
                                ),
                              ),
                              x.length > 0
                                  ? slider.sliderModel!.slider![index]
                                                  .movieId !=
                                              null ||
                                          slider.sliderModel!.slider![index]
                                                  .tvSeriesId !=
                                              null
                                      ? Padding(
                                          padding:
                                              EdgeInsets.only(bottom: 20.0),
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              backgroundColor: isLight
                                                  ? Colors.black
                                                      .withOpacity(0.7)
                                                  : Colors.white70,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10.0,
                                                  horizontal: 20.0),
                                            ),
                                            onPressed: () {
                                              print(
                                                  "here: ${slider.sliderModel!.slider![index].movieId}");
                                              print(
                                                  "here2: ${slider.sliderModel!.slider![index].tvSeriesId}");

                                              Navigator.pushNamed(context,
                                                  RoutePaths.videoDetail,
                                                  arguments:
                                                      VideoDetailScreen(x[0]));
                                            },
                                            icon: Icon(
                                              Icons.info_outline_rounded,
                                              color: isLight
                                                  ? buildLightTheme()
                                                      .primaryColorLight
                                                  : buildDarkTheme()
                                                      .primaryColorDark,
                                              size: 24.0,
                                            ),
                                            label: Text(
                                              translate('Detail___More'),
                                              style: TextStyle(
                                                color: isLight
                                                    ? buildLightTheme()
                                                        .primaryColorLight
                                                    : buildDarkTheme()
                                                        .primaryColorDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox.shrink()
                                  : SizedBox.shrink()
                            ],
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final slider =
        Provider.of<SliderProvider>(context, listen: false).sliderModel!;
    return slider.slider == null
        ? SizedBox.shrink()
        : Container(
            child: imageSlider(),
          );
  }
}
