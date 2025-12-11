import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Obx(() => auth.errorText.value.isNotEmpty
                  ? Text(auth.errorText.value,
                      style: const TextStyle(color: Colors.red))
                  : const SizedBox()),

              const SizedBox(height: 10),

              Obx(() => ElevatedButton(
                    onPressed: auth.isLoading.value
                        ? null
                        : () => auth.login(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            ),
                    child: auth.isLoading.value
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Login"),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
