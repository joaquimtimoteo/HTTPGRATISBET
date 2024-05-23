import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Teste de Roteamento'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => testRouting(context, 'http://facebook.com'),
                child: Text('Testar Facebook'),
              ),
              ElevatedButton(
                onPressed: () => testRouting(context, 'http://youtube.com'),
                child: Text('Testar YouTube'),
              ),
              ElevatedButton(
                onPressed: () => testRouting(context, 'http://google.com'),
                child: Text('Testar Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> testRouting(BuildContext context, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Teste de Roteamento'),
          content: Text(
            'Status Code: ${response.statusCode}\n'
            'Body: ${response.body.substring(0, 100)}...',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar'),
            ),
          ],
        ),
      );

      final config = {
        "log": {
          "access": "/var/log/v2ray/access.log",
          "error": "/var/log/v2ray/error.log",
          "loglevel": "warning"
        },
        "inbounds": [
          {
            "port": 1080,
            "protocol": "http",
            "settings": {
              "accounts": [
                {"user": "joaquimtimoteo", "pass": "Carlinhos12!"}
              ],
              "timeout": 600
            },
            "streamSettings": {
              "network": "tcp",
              "security": "none",
              "tcpSettings": {
                "header": {
                  "type": "http",
                  "request": {
                    "version": "1.1",
                    "method": "GET",
                    "path": ["/"],
                    "headers": {
                      "Host": ["facebook.com", "youtube.com", "google.com"]
                    }
                  }
                }
              }
            }
          },
          {
            "port": 1010,
            "protocol": "socks",
            "settings": {"auth": "noauth", "udp": false, "timeout": 600}
          },
          {
            "port": 1110,
            "protocol": "http",
            "settings": {"timeout": 600}
          }
        ],
        "outbounds": [
          {
            "protocol": "vmess",
            "settings": {
              "vnext": [
                {
                  "address": "20.42.93.21",
                  "port": 443,
                  "users": [
                    {"id": "a04be4ef-1797-4ca9-a549-4385ce42494c", "alterId": 0}
                  ]
                }
              ]
            },
            "tag": "vmess-outbound"
          },
          {
            "protocol": "socks",
            "settings": {
              "servers": [
                {"address": "127.0.0.1", "port": 1010, "users": []}
              ]
            },
            "tag": "socks-outbound"
          },
          {
            "protocol": "http",
            "settings": {
              "servers": [
                {"address": "127.0.0.1", "port": 1110, "users": []}
              ]
            },
            "tag": "http-outbound"
          }
        ],
        "routing": {
          "rules": [
            {
              "type": "field",
              "outboundTag": "direct",
              "domain": ["facebook.com", "youtube.com", "google.com"]
            },
            {
              "type": "field",
              "outboundTag": "vmess-outbound",
              "protocol": ["vmess"]
            },
            {
              "type": "field",
              "outboundTag": "socks-outbound",
              "protocol": ["socks"]
            },
            {
              "type": "field",
              "outboundTag": "http-outbound",
              "protocol": ["http"]
            }
          ],
          "settings": {
            "rules": [
              {
                "domainStrategy": "AsIs",
                "balancer": [
                  {
                    "tag": "balancer",
                    "selector": [
                      "vmess-outbound",
                      "socks-outbound",
                      "http-outbound"
                    ]
                  }
                ]
              }
            ]
          }
        }
      };

      final socket =
          await Socket.connect('20.42.93.21', 1010); // Porta do protocolo SOCKS
      final encoder = JsonEncoder();
      final configJson = encoder.convert(config);

      socket.write(configJson);

      socket.listen((List<int> data) {
        print('Received: ${String.fromCharCodes(data)}');
      });

      socket.close();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Teste de Roteamento'),
          content: Text('Erro: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar'),
            ),
          ],
        ),
      );
    }
  }
}
