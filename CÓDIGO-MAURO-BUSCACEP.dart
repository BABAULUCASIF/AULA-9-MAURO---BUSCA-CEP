import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 1. Função que busca o endereço na API do ViaCEP
Future<Endereco> buscaEndereco(String cep) async {
  final resposta = await http.get(
    Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final dados = jsonDecode(resposta.body);
    
    // O ViaCEP retorna um JSON com um campo 'erro' caso o CEP não exista
    if (dados.containsKey('erro') && dados['erro'] == true) {
      throw Exception('CEP não encontrado.');
    }
    
    return Endereco.fromJson(dados);
  } else {
    throw Exception('Falha ao carregar o endereço.');
  }
}

// 2. Modelo de Dados para o Endereço
class Endereco {
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;

  const Endereco({
    required this.logradouro,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      logradouro: json['logradouro'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Controlador para pegar o texto digitado no input do CEP
  final TextEditingController _cepController = TextEditingController();
  
  Future<Endereco>? enderecoFuturo;

  void _pesquisar() {
    final cep = _cepController.text.trim();
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um CEP válido com 8 dígitos.')),
      );
      return;
    }

    setState(() {
      enderecoFuturo = buscaEndereco(cep);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buscador de CEP',
      home: Scaffold(
        appBar: AppBar(title: const Text('Buscador de CEP - ViaCEP')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Campo para digitar o CEP
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Digite o CEP (somente números)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              
              // Botão para disparar a busca
              ElevatedButton(
                onPressed: _pesquisar,
                child: const Text('Buscar Endereço'),
              ),
              const SizedBox(height: 20),

              // Exibição dos dados usando FutureBuilder
              Expanded(
                child: enderecoFuturo == null
                    ? const Center(child: Text('Informe um CEP para começar.'))
                    : FutureBuilder<Endereco>(
                        future: enderecoFuturo,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          } else if (snapshot.hasData) {
                            final end = snapshot.data!;
                            return ListView(
                              children: [
                                Text('Rua: ${end.logradouro}'),
                                Text('Bairro: ${end.bairro}'),
                                Text('Cidade: ${end.localidade}'),
                                Text('Estado: ${end.uf}'),
                              ],
                            );
                          }
                          return const Text('Nenhum dado encontrado.');
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
