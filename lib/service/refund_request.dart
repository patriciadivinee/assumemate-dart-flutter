import 'package:assumemate/format.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';

class RefundRequest extends StatefulWidget {
  final String orderId;

  const RefundRequest({super.key, required this.orderId});
  @override
  State<RefundRequest> createState() => _RefundRequestState();
}

@override
class _RefundRequestState extends State<RefundRequest> {
  final ApiService apiService = ApiService();
  Map<String, dynamic> _refundDetails = {};
  bool _isLoading = false;

  Future<void> _getRefundDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.getRequestRefund(widget.orderId);

      print('refund na this');
      print(response);

      if (response.containsKey('refund')) {
        setState(() {
          _refundDetails = response['refund'];
        });
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    _getRefundDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xff4A8AF0),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFCF1),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Refund Request",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * .6,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.white,
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/15-removebg-preview.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),
                  createRow(
                      'Refund ID', _refundDetails['refund_id'].toString()),
                  const SizedBox(height: 15),
                  createRow('Requested By', _refundDetails['req_by']),
                  const SizedBox(height: 15),
                  createRow('Requested Date	',
                      timeFormat(_refundDetails['refund_created_at'])),
                  const SizedBox(height: 15),
                  createRow('Refund Amount',
                      formatCurrency(_refundDetails['refund_amnt'])),
                  const SizedBox(height: 15),
                  createRow('-Fee', formatCurrency(_refundDetails['fee'])),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Refund',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatCurrency(_refundDetails['tot_refund']),
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 50),
                  (_refundDetails['refund_status'] == 'REFUNDED')
                      ? Container(
                          padding: EdgeInsets.all(7),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Color(0xff34a36e),
                                size: 30,
                              ),
                              Expanded(
                                child: Text(
                                  'Your refund request has already been processed! Please check your PayPal account for confirmation.',
                                  style: TextStyle(letterSpacing: 1),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                ),
                              )
                            ],
                          ))
                      : _refundDetails['refund_status'] == 'PENDING'
                          ? Container(
                              padding: EdgeInsets.all(7),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Color(0xff4A8AF0),
                                    size: 30,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'We’re processing your refund request. Please allow up to 3-7 business days for completion.',
                                      style: TextStyle(letterSpacing: 1),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                    ),
                                  )
                                ],
                              ))
                          : const SizedBox.shrink()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget createRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
