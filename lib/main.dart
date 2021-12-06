import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: 'Suite IT Loterias', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  static const OPERATING_CHAIN = 97;

  final wc = WalletConnectProvider.binance();

  Web3Provider? web3wc;

  var balance;
  var address;
  var chainId;
  var transactionCount;

  var prizePool;

  String lotteryContractAddress = "0x0c52a7c79Db04Fb6C6093AecD3Ca4e216739Ae1e";

  final abi = [
    "function getBalance() public view returns(uint)",
    "function random() public view returns(uint)",
    "function pickWinner() public",

    // An event triggered whenever anyone transfers to someone else
    //"event Transfer(address indexed from, address indexed to, uint amount)"
  ];

  connectProvider() async {
    if (Ethereum.isSupported) {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        currentChain = await ethereum!.getChainId();
      }

      update();
    }
  }

  connectWC() async {
    await wc.connect();
    if (wc.connected) {
      currentAddress = wc.accounts.first;
      currentChain = 97;
      wcConnected = true;
      web3wc = Web3Provider.fromWalletConnect(wc);
    }

    update();
  }

  clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;
    web3wc = null;

    update();
  }

  init() {
    if (Ethereum.isSupported) {
      connectProvider();

      ethereum!.onAccountsChanged((accs) {
        clear();
      });

      ethereum!.onChainChanged((chain) {
        clear();
      });
    }
  }

  getLastestBlock() async {
    print(await provider!.getLastestBlock());
    print(await provider!.getLastestBlockWithTransaction());
  }

  testProvider() async {
    final rpcProvider = JsonRpcProvider('https://bsc-dataseed.binance.org/');
    print(rpcProvider);
    var network = await rpcProvider.getNetwork();
    print("Connected to: " + network.toString());
    var balance = await rpcProvider.getBalance(currentAddress);
    print("Balance: ${balance.toString()}");
  }

  test() async {
    // Get signer from provider
    final signer = provider!.getSigner();

    balance = await signer.getBalance();

    balance = EthUtils.formatEther(balance.toString());
    balance = double.parse(balance).toStringAsFixed(4);
    print(balance);
    address = await signer.getAddress();
    chainId = await signer.getChainId();
    transactionCount = await signer.getTransactionCount();
    update();

    // Get account balance
    //   var balance = await signer.(); // 315752957360231815
    //   print("Balance: ${balance}");
  }

  getPrizePool() async {
    final lottery = Contract(lotteryContractAddress, abi, provider!.getSigner());
    var y = await lottery.call<BigInt>('getBalance');
    prizePool = EthUtils.formatEther(y.toString());

    update();
  }

  pickWinner() async {
    final lottery = Contract(lotteryContractAddress, abi, provider!.getSigner());
    var y = await lottery.call<void>('pickWinner');
    // print(y);
    // prizePool = EthUtils.formatEther(y.toString());

    // update();
  }

  join() async {
    final signer = provider!.getSigner();

    final tx = await signer.sendTransaction(
      TransactionRequest(
        to: lotteryContractAddress,
        value: BigInt.from(100000000000000000),
      ),
    ); // Send 100000000000000000 wei to `0xbar`

    tx.hash; // 0xbash
  }

  testSwitchChain() async {
    await ethereum!.walletSwitchChain(97, () async {
      await ethereum!.walletAddChain(
        chainId: 97,
        chainName: 'Binance Testnet',
        nativeCurrency: CurrencyParams(name: 'BNB', symbol: 'BNB', decimals: 18),
        rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
      );
    });
  }

  @override
  void onInit() {
    init();

    super.onInit();
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (h) => Scaffold(
        body: Center(
          child: Column(children: [
            Container(height: 10),
            Builder(builder: (_) {
              var shown = '';
              if (h.isConnected && h.isInOperatingChain)
                shown = 'Você está conectado!';
              else if (h.isConnected && !h.isInOperatingChain)
                shown = 'Rede errada! Por favor se conecte a BSC TestNet.(97)';
              else if (Ethereum.isSupported)
                return Column(
                  children: [
                    OutlinedButton(child: Text('Conectar'), onPressed: h.connectProvider),
                    TextButton(
                        onPressed: h.testSwitchChain, child: Text('Adicionar BSC Testnet na minha carteira!')),
                  ],
                );
              else
                shown = 'Seu browser não é suportado!';

              return Text(shown,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20));
            }),
            Container(height: 30),
            if (h.isConnected && h.isInOperatingChain) ...[
              // TextButton(onPressed: h.getLastestBlock, child: Text('get lastest block')),
              // Container(height: 10),
              // TextButton(
              //     onPressed: h.testProvider, child: Text('test binance rpc provider')),
              // Container(height: 10),
              TextButton(
                  onPressed: h.test,
                  child: Text('Carregar informações da minha carteira')),
              Text("Endereço da carteira: ${h.address}"),
              Text("Saldo da carteira: ${h.balance} BNB"),
              Text("ID da chain: ${h.chainId}"),
              Text("Nro de transações feitas: ${h.transactionCount}"),
              Container(height: 10),
              TextButton(
                  onPressed: h.join,
                  child: Text('Participar do sorteio (Ticket: 0.1 BNB)')),
              h.address == '0x9c14d95A7A70c97d0cf93cDA150898025A1F2CDd'
                  ? Text("Valor do prêmio atual (BNB): ${h.prizePool.toString()}") : Container(),
              Container(height: 10),
              h.address == '0x9c14d95A7A70c97d0cf93cDA150898025A1F2CDd'
                  ? TextButton(
                      onPressed: h.getPrizePool,
                      child: Text('Obter valor do prêmio atual'),
                    )
                  : Container(),
              h.address == '0x9c14d95A7A70c97d0cf93cDA150898025A1F2CDd'
                  ? TextButton(
                      onPressed: h.pickWinner,
                      child: Text('Sortear vencedor'),
                    )
                  : Container(),
            ],
            // Container(height: 30),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Text('Wallet Connect connected: ${h.wcConnected}'),
            //     Container(width: 10),
            //     OutlinedButton(child: Text('Connect to WC'), onPressed: h.connectWC)
            //   ],
            // ),
            Container(height: 30),
            if (h.wcConnected && h.wc.connected) ...[
              Text(h.wc.walletMeta.toString()),
            ],
          ]),
        ),
      ),
    );
  }
}
