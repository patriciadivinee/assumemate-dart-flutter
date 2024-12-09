import 'package:assumemate/components/listing_item.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> searchResults = [];
  List<dynamic> allListings = [];
  List<dynamic> filteredListings = [];

  final SecureStorage secureStorage = SecureStorage();
  final baseURL = dotenv.env['API_URL'] ?? '';
  String selectedCategory = '';
  RangeValues priceRange = const RangeValues(0, 10000000);
  int bedroomCount = 0;
  int bathroomCount = 0;
  double lotArea = 0;
  double floorArea = 0;
  String make = '';
  String yearModel = '';
  String fuelType = '';
  String transmissionType = '';
  String mileage = '';
  String color = '';

  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.black,
    Colors.white,
    Colors.grey
  ];
  Color? selectedColor;

  final List<String> categories = ['Real Estate', 'Car', 'Motorcycle'];
  final List<String> transmissionTypes = ['Manual', 'Automatic', 'Hybrid'];
  final List<String> fuelTypes = ['Gasoline', 'Diesel', 'Electric', 'Hybrid'];

  final OutlineInputBorder borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(30.0),
    borderSide: const BorderSide(color: Colors.black),
  );

  @override
  void initState() {
    super.initState();
    fetchAllListings();
    _searchController.addListener(() {
      filterSearchResults(_searchController.text);
    });
  }

  void filterListings(String category) {
    setState(() {
      if (category == 'Real Estate') {
        filteredListings = filterRealEstateListings(allListings);
      } else if (category == 'Motorcycle' || category == 'Car') {
        filteredListings = filterVehicleListings(allListings, category);
      }
    });
  }

  Future<void> fetchAllListings() async {
    final token = await secureStorage.getToken();

    try {
      final apiUrl = Uri.parse('$baseURL/listing/searchview/');
      print('Fetching all listings from: $apiUrl');

      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        var listings = json.decode(response.body);
        print('Listings fetched: ${json.encode(listings)}');
        setState(() {
          allListings = listings;
          searchResults = List.from(allListings);
        });
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load listings');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load listings');
    }
  }

  void filterSearchResults(String query) {
    print('Starting filter with query: $query');
    List<dynamic> filteredResults = List.from(allListings);

    if (query.isNotEmpty) {
      filteredResults = filteredResults.where((listing) {
        var content = listing['list_content'] ?? {};
        String title = content['title']?.toString().toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    }

    if (selectedCategory.isNotEmpty) {
      print('Applying category filter: $selectedCategory');

      filteredResults = filteredResults.where((listing) {
        var content = listing['list_content'] ?? {};
        String category = content['category']?.toString().toLowerCase() ?? '';
        return category == selectedCategory.toLowerCase();
      }).toList();

      if (selectedCategory == 'Real Estate') {
        filteredResults = filterRealEstateListings(filteredResults);
      } else if (selectedCategory == 'Car' ||
          selectedCategory == 'Motorcycle') {
        filteredResults =
            filterVehicleListings(filteredResults, selectedCategory);
      }
    }

    if (priceRange.start > 0 || priceRange.end < 10000000) {
      filteredResults = filteredResults.where((listing) {
        var content = listing['list_content'] ?? {};
        double price =
            double.tryParse(content['price']?.toString() ?? '0') ?? 0;
        return price >= priceRange.start && price <= priceRange.end;
      }).toList();
    }

    setState(() {
      searchResults = filteredResults;
      print('Final results count: ${filteredResults.length}');
    });
  }

  void debugPrintListing(dynamic listing) {
    print('\n--- Listing Debug Info ---');
    print('List ID: ${listing['list_id']}');
    print('Content: ${listing['list_content']}');
    if (listing['list_content'] != null) {
      var content = listing['list_content'];
      print('Category: ${content['category']}');
      print('Bedrooms: ${content['bedrooms']}');
      print('Bathrooms: ${content['bathrooms']}');
      print('Make: ${content['make']}');
      print('Year: ${content['year']}');
      print('Price: ${content['price']}');
    }
    print('------------------------\n');
  }

  List<dynamic> filterRealEstateListings(List<dynamic> listings) {
    return listings.where((listing) {
      var content = listing['list_content'] ?? {};

      int listingBedrooms =
          int.tryParse(content['bedrooms']?.toString().split(' ')[0] ?? '0') ??
              0;

      int listingBathrooms =
          int.tryParse(content['bathrooms']?.toString().split(' ')[0] ?? '0') ??
              0;

      double listingLotArea = content['lotArea']?.toString().isEmpty ?? true
          ? 0.0
          : double.tryParse(content['lotArea']?.toString() ?? '0') ?? 0.0;

      double listingFloorArea = content['floorArea']?.toString().isEmpty ?? true
          ? 0.0
          : double.tryParse(content['floorArea']?.toString() ?? '0') ?? 0.0;

      print('Listing values:');
      print('Bedrooms: $listingBedrooms (Filter: $bedroomCount)');
      print('Bathrooms: $listingBathrooms (Filter: $bathroomCount)');
      print('Lot Area: $listingLotArea (Filter: $lotArea)');
      print('Floor Area: $listingFloorArea (Filter: $floorArea)');

      bool bedroomMatch = bedroomCount <= 0 || listingBedrooms == bedroomCount;
      bool bathroomMatch =
          bathroomCount <= 0 || listingBathrooms == bathroomCount;
      bool lotAreaMatch = lotArea <= 0 || listingLotArea >= lotArea;
      bool floorAreaMatch = floorArea <= 0 || listingFloorArea >= floorArea;

      return bedroomMatch && bathroomMatch && lotAreaMatch && floorAreaMatch;
    }).toList();
  }

  List<dynamic> filterVehicleListings(
      List<dynamic> listings, String vehicleType) {
    return listings.where((listing) {
      var content = listing['list_content'] ?? {};
      String listingCategory =
          content['category']?.toString().toLowerCase() ?? '';
      if (listingCategory != vehicleType.toLowerCase()) {
        return false;
      }

      String listingMake = content['make']?.toString().toLowerCase() ?? '';
      String listingYear = content['year']?.toString() ?? '';
      String listingTransmission =
          content['transmission']?.toString().toLowerCase() ?? '';
      String listingFuelType =
          content['fuelType']?.toString().toLowerCase() ?? '';
      String listingMileage = content['mileage']?.toString() ?? '';

      String listingColor = content['color']?.toString() ?? '';
      String extractedColor = extractColorFromMaterialString(listingColor);

      // Debug prints
      print('Vehicle Filter Values:');
      print('Make: $listingMake (Filter: $make)');
      print('Year: $listingYear (Filter: $yearModel)');
      print('Transmission: $listingTransmission (Filter: $transmissionType)');
      print('Fuel Type: $listingFuelType (Filter: $fuelType)');
      print(
          'Color: $extractedColor (Filter: ${selectedColor != null ? getColorName(selectedColor!) : "none"})');
      print('Mileage: $listingMileage (Filter: $mileage)');

      bool makeMatch = make.isEmpty || listingMake.contains(make.toLowerCase());
      bool yearMatch = yearModel.isEmpty || listingYear == yearModel;
      bool transmissionMatch = transmissionType.isEmpty ||
          listingTransmission == transmissionType.toLowerCase();
      bool fuelTypeMatch =
          fuelType.isEmpty || listingFuelType == fuelType.toLowerCase();

      bool colorMatch = selectedColor == null ||
          extractedColor == getColorName(selectedColor!).toLowerCase();

      bool mileageMatch =
          mileage.isEmpty || matchMileageRange(listingMileage, mileage);

      return makeMatch &&
          yearMatch &&
          transmissionMatch &&
          fuelTypeMatch &&
          colorMatch &&
          mileageMatch;
    }).toList();
  }

  String extractColorFromMaterialString(String materialColorString) {
    if (materialColorString.contains('0xfff44336')) return 'red';
    if (materialColorString.contains('0xff2196f3')) return 'blue';
    if (materialColorString.contains('0xff4caf50')) return 'green';
    if (materialColorString.contains('0xffffeb3b')) return 'yellow';
    if (materialColorString.contains('0xffff9800')) return 'orange';
    if (materialColorString.contains('0xff000000')) return 'black';
    if (materialColorString.contains('0xffffffff')) return 'white';
    if (materialColorString.contains('0xff9e9e9e')) return 'grey';
    return '';
  }

  String getColorName(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.yellow) return 'yellow';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.black) return 'black';
    if (color == Colors.white) return 'white';
    if (color == Colors.grey) return 'grey';
    return '';
  }

  bool matchMileageRange(String listingMileage, String filterRange) {
    if (filterRange.isEmpty) return true;

    // Remove 'km' and any whitespace from both the listing mileage and filter range
    listingMileage = listingMileage.replaceAll(RegExp(r'[^\d-]'), '');
    filterRange = filterRange.replaceAll(RegExp(r'[^\d-]'), '');

    List<String> rangeParts = filterRange.split('-');
    if (rangeParts.length != 2) return false;

    int rangeStart = int.tryParse(rangeParts[0].replaceAll(',', '')) ?? 0;
    int rangeEnd = int.tryParse(rangeParts[1].replaceAll(',', '')) ?? 0;

    // If the listing mileage is already a range
    if (listingMileage.contains('-')) {
      List<String> listingRangeParts = listingMileage.split('-');
      int listingStart =
          int.tryParse(listingRangeParts[0].replaceAll(',', '')) ?? 0;
      int listingEnd =
          int.tryParse(listingRangeParts[1].replaceAll(',', '')) ?? 0;

      // Check if the ranges overlap
      return (listingStart <= rangeEnd && listingEnd >= rangeStart);
    }

    // If listing mileage is a single number
    int listingMileageNum =
        int.tryParse(listingMileage.replaceAll(',', '')) ?? 0;

    return listingMileageNum >= rangeStart && listingMileageNum <= rangeEnd;
  }

  Widget buildVehicleFilters(String vehicleType) {
    final List<String> mileageRanges = [
      '0-10,000 km',
      '10,001-20,000 km',
      '20,001-30,000 km',
      '30,001-40,000 km',
      '40,001-50,000 km',
      '50,001-60,000 km',
      '60,001-70,000 km',
      '70,001-80,000 km',
      '80,001-90,000 km',
      '90,001-100,000 km',
      '100,001-110,000 km',
      '110,001-120,000 km',
      '120,001-130,000 km',
      '130,001-140,000 km',
      '140,001-150,000 km',
      '150,001-160,000 km',
      '160,001-170,000 km',
      '170,001-180,000 km',
      '180,001-190,000 km',
      '190,001-200,000 km',
    ];

    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.black,
      Colors.white,
      Colors.grey
    ];

    Widget buildColorGrid() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Color', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((color) {
                final bool isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: color == Colors.white ? Colors.grey : color,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        buildTextInput('$vehicleType Make', (value) {
          setState(() => make = value);
        }),
        const SizedBox(height: 8),
        buildNumberInput('Year Model', (value) {
          setState(() => yearModel = value);
        }),
        const SizedBox(height: 8),
        buildDropdownField('Fuel Type', fuelTypes, fuelType, (String? value) {
          setState(() => fuelType = value ?? '');
        }),
        const SizedBox(height: 8),
        buildDropdownField(
            'Transmission Type', transmissionTypes, transmissionType,
            (String? value) {
          setState(() => transmissionType = value ?? '');
        }),
        const SizedBox(height: 8),
        buildDropdownField('Mileage', mileageRanges, mileage, (String? value) {
          setState(() => mileage = value ?? '');
        }),
        const SizedBox(height: 16),
        buildColorGrid(),
      ],
    );
  }

  void selectColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = selectedColor ?? Colors.transparent;
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (Color color) {
                setState(() => tempColor = color);
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                setState(() {
                  selectedColor = tempColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void clearFilters() {
    setState(() {
      bedroomCount = 0;
      bathroomCount = 0;
      lotArea = 0.0;
      floorArea = 0.0;

      selectedCategory = '';
      make = '';
      yearModel = '';
      fuelType = '';
      transmissionType = '';
      color = '';
      mileage = '';
    });
  }

  void resetFilters() {
    setState(() {
      make = '';
      yearModel = '';
      fuelType = '';
      transmissionType = '';
      mileage = '';
      color = '';
      bedroomCount = 0;
      bathroomCount = 0;
      lotArea = 0;
      floorArea = 0;
      priceRange = const RangeValues(0, 10000000);
    });
  }

  void clearFiltersAndResetListings() {
    setState(() {
      clearFilters();
      filteredListings = allListings;
    });
  }

  void applyFilters() {
    filterSearchResults(_searchController.text);
    Navigator.pop(context);
  }

  Widget buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
        border: borderStyle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          if (label == 'Category') {
            resetFilters();
          }
          onChanged(newValue);
        });
      },
    );
  }

  Widget buildFilterDrawer() {
    int activeFilterCount = 0;
    if (selectedCategory.isNotEmpty) activeFilterCount++;
    if (priceRange.start > 0 || priceRange.end < 10000000) activeFilterCount++;
    if (bedroomCount > 0) activeFilterCount++;
    if (bathroomCount > 0) activeFilterCount++;
    if (lotArea > 0) activeFilterCount++;
    if (floorArea > 0) activeFilterCount++;
    if (make.isNotEmpty) activeFilterCount++;
    if (yearModel.isNotEmpty) activeFilterCount++;
    if (fuelType.isNotEmpty) activeFilterCount++;
    if (transmissionType.isNotEmpty) activeFilterCount++;
    if (mileage.isNotEmpty) activeFilterCount++;
    if (selectedColor != null) activeFilterCount++;

    return Drawer(
      backgroundColor: Color(0xffFFFCF1),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$activeFilterCount active ${activeFilterCount == 1 ? 'filter' : 'filters'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          if (_hasActiveFilters()) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActiveFiltersChips(),
                  const Divider(thickness: 1),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                buildDropdownField(
                  'Category',
                  categories,
                  selectedCategory,
                  (String? newValue) {
                    setState(() {
                      selectedCategory = newValue ?? '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Price Range (PHP)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RangeSlider(
                  activeColor: const Color(0xff4A8AF0),
                  values: priceRange,
                  min: 0,
                  max: 10000000,
                  divisions: 100,
                  labels: RangeLabels(
                    'PHP ${priceRange.start.round()}',
                    'PHP ${priceRange.end.round()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      priceRange = values;
                    });
                  },
                ),
                if (selectedCategory == 'Real Estate') ...[
                  buildRealEstateFilters(),
                ] else if (selectedCategory == 'Car') ...[
                  buildCarFilters(),
                ] else if (selectedCategory == 'Motorcycle') ...[
                  buildMotorcycleFilters(),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          filterSearchResults(_searchController.text);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A8AF0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        print('cleared');
                        setState(() {
                          clearFiltersAndResetListings();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 9),
                        side: const BorderSide(
                            color: Color(0xff4A8AF0), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Color(0xFF4A8AF0)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    List<Widget> chips = [];

    void addChip(String label, String value,
        {String? prefix, Function()? onRemove}) {
      if (value.isNotEmpty && value != '0') {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: FilterChip(
              label: Text(
                '${prefix ?? label}: $value',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.blue.shade100,
              onSelected: (_) {},
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: onRemove,
            ),
          ),
        );
      }
    }

    if (selectedCategory.isNotEmpty) {
      addChip('Category', selectedCategory, onRemove: () {
        setState(() {
          selectedCategory = '';

          resetCategorySpecificFilters();
          filterSearchResults(_searchController.text);
        });
      });
    }

    if (priceRange.start > 0 || priceRange.end < 10000000) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
          child: FilterChip(
            label: Text(
              'Price: ₱${priceRange.start.round()} - ₱${priceRange.end.round()}',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.blue.shade100,
            onSelected: (_) {},
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: () {
              setState(() {
                priceRange = const RangeValues(0, 10000000);
                filterSearchResults(_searchController.text);
              });
            },
          ),
        ),
      );
    }

    if (selectedCategory == 'Real Estate') {
      if (bedroomCount > 0) {
        addChip('Bedrooms', bedroomCount.toString(), onRemove: () {
          setState(() {
            bedroomCount = 0;
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (bathroomCount > 0) {
        addChip('Bathrooms', bathroomCount.toString(), onRemove: () {
          setState(() {
            bathroomCount = 0;
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (lotArea > 0) {
        addChip('Lot Area', '${lotArea.toString()} sqm', onRemove: () {
          setState(() {
            lotArea = 0;
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (floorArea > 0) {
        addChip('Floor Area', '${floorArea.toString()} sqm', onRemove: () {
          setState(() {
            floorArea = 0;
            filterSearchResults(_searchController.text);
          });
        });
      }
    }

    if (selectedCategory == 'Car' || selectedCategory == 'Motorcycle') {
      if (make.isNotEmpty) {
        addChip('Make', make, onRemove: () {
          setState(() {
            make = '';
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (yearModel.isNotEmpty) {
        addChip('Year', yearModel, onRemove: () {
          setState(() {
            yearModel = '';
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (fuelType.isNotEmpty) {
        addChip('Fuel', fuelType, onRemove: () {
          setState(() {
            fuelType = '';
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (transmissionType.isNotEmpty) {
        addChip('Transmission', transmissionType, onRemove: () {
          setState(() {
            transmissionType = '';
            filterSearchResults(_searchController.text);
          });
        });
      }
      if (mileage.isNotEmpty) {
        addChip('Mileage', mileage, onRemove: () {
          setState(() {
            mileage = '';
            filterSearchResults(_searchController.text);
          });
        });
      }
      // Updated color chip
      if (selectedColor != null) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: selectedColor,
                      border: selectedColor == Colors.white
                          ? Border.all(color: Colors.grey)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    'Color: ${getColorName(selectedColor!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.blue.shade100,
              onSelected: (_) {},
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  selectedColor = null;
                  filterSearchResults(_searchController.text);
                });
              },
            ),
          ),
        );
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  void resetCategorySpecificFilters() {
    bedroomCount = 0;
    bathroomCount = 0;
    lotArea = 0;
    floorArea = 0;
    make = '';
    yearModel = '';
    fuelType = '';
    transmissionType = '';
    mileage = '';
    color = '';
  }

  bool _hasActiveFilters() {
    return selectedCategory.isNotEmpty ||
        priceRange.start > 0 ||
        priceRange.end < 10000000 ||
        bedroomCount > 0 ||
        bathroomCount > 0 ||
        lotArea > 0 ||
        floorArea > 0 ||
        make.isNotEmpty ||
        yearModel.isNotEmpty ||
        fuelType.isNotEmpty ||
        transmissionType.isNotEmpty ||
        mileage.isNotEmpty ||
        color.isNotEmpty;
  }

  Widget buildCarFilters() {
    return buildVehicleFilters('Car');
  }

  Widget buildMotorcycleFilters() {
    return buildVehicleFilters('Motorcycle');
  }

  Widget buildRealEstateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        buildNumberInput('Bedroom Count', (value) {
          setState(() => bedroomCount = int.tryParse(value) ?? 0);
        }),
        const SizedBox(height: 8),
        buildNumberInput('Bathroom Count', (value) {
          setState(() => bathroomCount = int.tryParse(value) ?? 0);
        }),
        const SizedBox(height: 8),
        buildNumberInput('Lot Area (sqm)', (value) {
          setState(() => lotArea = double.tryParse(value) ?? 0);
        }),
        const SizedBox(height: 8),
        buildNumberInput('Floor Area (sqm)', (value) {
          setState(() => floorArea = double.tryParse(value) ?? 0);
        }),
      ],
    );
  }

  Widget buildTextInput(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
        border: borderStyle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget buildNumberInput(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
        border: borderStyle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget buildDropdownField(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return DropdownButtonFormField2<String>(
      value: value.isEmpty ? null : value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.only(left: 2, right: 15, top: 10, bottom: 10),
        enabledBorder: borderStyle,
        focusedBorder: borderStyle,
        border: borderStyle,
      ),
      dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
        color: const Color(0xffFFFCF1),
        borderRadius: BorderRadius.circular(14),
      )),
      hint: Text(label),
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (label == 'Category') {
          resetFilters();
        }
        onChanged(newValue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          color: const Color(0xff4A8AF0),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _searchController,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: borderStyle,
                    enabledBorder: borderStyle,
                    focusedBorder: borderStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      endDrawer: buildFilterDrawer(),
      body: Column(
        children: [
          Expanded(
            child: searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: buildSearchGrid(searchResults),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchGrid(List<dynamic> listings) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        mainAxisExtent: MediaQuery.of(context).size.width * .50,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        var listing = listings[index];

        return ListingItem(
          listing: listing,
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
