pragma solidity ^0.4.26;

/**
 * オラクルコントラクト
 */
contract Oracle {
    uint256 public divisor;
    // データ要求開始
    function initRequest(uint256 queryType, function(uint256) external onSuccess,function(uint256) external onFailure) public returns (uint256 id);
    function addArgumentToRequestUint(uint256 id, bytes32 name, uint256 arg) public;
    function addArgumentToRequestString(uint256 id, bytes32 name, bytes32 arg) public;
    // 要求を実行する。
    function executeRequest(uint256 id) public;
    function getResponseUint(uint256 id, bytes32 name) public constant returns(uint256);
    function getResponseString(uint256 id, bytes32 name) public constant returns(bytes32);
    function getResponseError(uint256 id) public constant returns(bytes32);
    function deleteResponse(uint256 id) public constant;
}

/**
 * 市場データのためにBlockOne IQ サービスを呼び出すサービス
 */
contract OracleB1IQClient {
    // オラクルをインスタンス化する。
    Oracle private oracle;
    // イベントを設定する。
    event LogError(bytes32 description);

    function OracleB1IQClient(address addr) public payable {
        oracle = Oracle(addr);
        // IBMの株価を取得する。
        getIntraday("IBM", now);
    }

    function getIntraday(bytes32 ric, uint256 timestamp) public {
        // 要求を開始する。(利用可能フィールドを返す。)
        uint256 id = oracle.initRequest(0, this.handleSuccess, this.handleFailure);
        // リクエストするためのコードを設定する。
        oracle.addArgumentToRequestString(id, "symbol", ric);
        oracle.addArgumentToRequestUint(id, "timestamp", timestamp);
        // リクエストを実行する。(IBMの株価を入手することができる。)
        oracle.executeRequest(id);
    }
    
    // onSuccessコールバック関数
    // @id 利用可能コード
    function handleSuccess(uint256 id) public {
        assert(msg.sender == address(oracle));
        // 利用可能コードによって変化する。
        bytes32 ric = oracle.getResponseString(id, "symbol");
        uint256 open = oracle.getResponseUint(id, "open");
        uint256 high = oracle.getResponseUint(id, "high");
        uint256 low = oracle.getResponseUint(id, "low");
        uint256 close = oracle.getResponseUint(id, "close");
        uint256 bid = oracle.getResponseUint(id, "bid");
        uint256 ask = oracle.getResponseUint(id, "ask");
        uint256 timestamp = oracle.getResponseUint(id, "timestamp");
        oracle.deleteResponse(id);
        // 価格データを使って何かをする。
    }
    
    // onFailureコールバック関数
    function handleFailure(uint256 id) public {
        assert(msg.sender == address(oracle));
        bytes32 error = oracle.getResponseError(id);
        oracle.deleteResponse(id);
        emit LogError(error);
    }
}
