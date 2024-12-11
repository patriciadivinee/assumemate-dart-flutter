import 'package:assumemate/format.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';

class PayoutRequest extends StatefulWidget {
  final String orderId;

  const PayoutRequest({super.key, required this.orderId});
  @override
  State<PayoutRequest> createState() => _PayoutRequestState();
}

@override
class _PayoutRequestState extends State<PayoutRequest> {
  final ApiService apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isChecked = false;

  Map<String, dynamic> _payoutDetails = {};

  void getPayoutDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.getRequestPayout(widget.orderId);

      print('payout na this');
      print(response);

      if (response.containsKey('payout')) {
        setState(() {
          _payoutDetails = response['payout'];
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

  void requestPayout() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    print('email');
    print(email);
    print(widget.orderId);

    try {
      final response = await apiService.requestPayout(widget.orderId, email);

      if (response.containsKey('payout')) {
        // Navigator.pop(context);
        getPayoutDetails();
        popUp(context, 'Payout request sent!');
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
    getPayoutDetails();
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
          "Request Payout",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _payoutDetails.isNotEmpty
          ? Center(
              child: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * .7,
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
                        createRow('Payout ID',
                            _payoutDetails['payout_id'].toString()),
                        const SizedBox(height: 15),
                        createRow('Payout to (PayPal)',
                            _payoutDetails['payout_paypal_email']),
                        const SizedBox(height: 15),
                        createRow('Requested By', _payoutDetails['req_by']),
                        const SizedBox(height: 15),
                        createRow('Requested Date	',
                            timeFormat(_payoutDetails['payout_created_at'])),
                        const SizedBox(height: 15),
                        createRow('Payout Amount',
                            formatCurrency(_payoutDetails['payout_amnt'])),
                        const SizedBox(height: 15),
                        createRow(
                            '-Fee', formatCurrency(_payoutDetails['fee'])),
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total Payout',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              formatCurrency(_payoutDetails['tot_payout']),
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        const SizedBox(height: 50),
                        (_payoutDetails['payout_status'] == 'SENT')
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
                                        'Your payout has already been processed! Please check your PayPal account for confirmation.',
                                        style: TextStyle(letterSpacing: 1),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    )
                                  ],
                                ))
                            : _payoutDetails['payout_status'] == 'PENDING'
                                ? Container(
                                    padding: EdgeInsets.all(7),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty,
                                          color: Color(0xff4A8AF0),
                                          size: 30,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'We’re processing your payout request. Please allow up to 3-7 business days for completion.',
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
            )
          : Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your transaction is successfully completed. You are now eligible to request a payout for this transaction. To proceed, kindly provide your PayPal email address and ensure that the email is correct to avoid any delays in processing your payment.',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),
                    // Padding(
                    //   padding: EdgeInsets.only(bottom: 8, right: 12, left: 12),
                    //   child: const Text(
                    //     'ENTER PAYPAL EMAIL',
                    //     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    //   ),
                    // ),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        TextFormField(
                          controller: _emailController,
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          style: const TextStyle(fontSize: 12),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            hintText: 'PAYPAL EMAIL',
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                )),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                )),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                )),
                            prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 10),
                                child: Icon(Icons.email)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Paypal email';
                            } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    CheckboxListTile(
                      title: Text(
                        "By proceeding, I confirm that all the information entered is correct, and I accept full responsibility for any discrepancies or errors in the information submitted.",
                        style: TextStyle(fontSize: 12), // Smaller text size
                      ),
                      value: _isChecked,
                      onChanged: (value) {
                        setState(() {
                          _isChecked = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor:
                          const Color(0xff4A8AF0), // Change active color
                      checkColor: Colors.white, // Change check mark color
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: (_isLoading && !_isChecked)
                          ? null
                          : () {
                              if (_formKey.currentState!.validate() &&
                                  _isChecked) {
                                // _requestResetPassword();
                                requestPayout();
                              }
                            },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(!_isChecked
                            ? Colors.grey.shade400
                            : const Color(0xff4A8AF0)),
                        minimumSize: WidgetStateProperty.all(
                            const Size(double.infinity, 50)),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      child: (_isLoading)
                          ? const SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: Color(0xffFFFCF1),
                              ),
                            )
                          : const Text(
                              "Confirm",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ]),
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
