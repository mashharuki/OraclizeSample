pragma solidity >= 0.5.0;

/**
 * Oraclizeを利用して外部ソースからETH/USD為替レートを取得・更新するコントラクト
 */
import "http://github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";

contract EthUsdPriceTicker  is usingOraclize {
    // ETH/USD価格
    uint public ethUsd;
    // イベントを設定する。
    event newOraclizeQuery(string description);
    event newCallbackResult(string result);
    
    constructor () public payable {
        // IPFS上のTLSNプルーフ生成とストレージに信号を送る。
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        // 問い合わせ要求
        queryTicker();
    }
    
    function __callback (bytes32 _queryId, string memory _result,  bytes memory _proof) public {
        if (msg.sender != oraclize_cbAddress()) {
            revert ();
        }
        // イベントの呼び出し
        emit newCallbackResult(_result);
        // 結果の文字列を符号なし整列に解析する。
        ethUsd = parseInt(_result, 2);
        // 価格をポーリングしているでコールバックから呼び出される。
        queryTicker();
    }
    
    // 問い合わせ要求用メソッド
    function queryTicker () public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            // イベントの呼び出し
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            // イベントの呼び出し
            emit newOraclizeQuery("Oraclize query was NOT sent, standing by for the answer...");
            // クエリパラメータは、JsonPathを指定してJson APIの結果の特定の部分を取得する
            oraclize_query (60 * 10, "URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,GBP).USD");
        }
    }
}

