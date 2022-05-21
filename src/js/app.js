App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  hasVoted: false,

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // TODO: refactor conditional
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  initContract: function() {
    $.getJSON("EutMusic.json", function(eutmusic) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.EutMusic = TruffleContract(eutmusic);
      // Connect provider to interact with contract
      App.contracts.EutMusic.setProvider(App.web3Provider);

      App.listenForEvents();

      return App.render();
    });
  },

  // Listen for events emitted from the contract
  listenForEvents: function() {
    App.contracts.EutMusic.deployed().then(function(instance) {
      // Restart Chrome if you are unable to receive this event
      // This is a known issue with Metamask
      // https://github.com/MetaMask/metamask-extension/issues/2393
      instance.mintedEvent({}, {
        fromBlock: 0,
        toBlock: 'latest'
      }).watch(function(error, event) {
        console.log("event triggered", event)
        // Reload when a new vote is recorded
        App.render();
      });
    });
  },

  render: function() {
    var eutmusicInstance;
    var loader = $("#loader");
    var content = $("#content");

    loader.show();
    content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Music Investor Account: " + account);
      }
    });

    // Load contract data
    App.contracts.EutMusic.deployed().then(function(instance) {
      eutmusicInstance = instance;

      return eutmusicInstance.totalSupply();
    }).then(function(musicCount) {
      console.log("music detected  "+musicCount);
      var candidatesResults = $("#candidatesResults");
      candidatesResults.empty();

      var candidatesSelect = $('#candidatesSelect');
      candidatesSelect.empty();

      for (var token_id = 0; token_id < musicCount; token_id++) {
        console.log(token_id);
        var token_id = token_id;

        eutmusicInstance.tokenURI(token_id).then(function(url) {
          console.log(url);
          var id = url;
          var name = url;
          // Render candidate Result
          var candidateTemplate = "<tr><th>" + id + "</th><td>" + name + "</td><td>" + token_id + "</td>"
              + "<td> "
              + "<form onSubmit=\"App.buy(); return false;\">"
              + "<button type=\"submit\" class=\"btn btn-primary\">buy</button> </form></td></tr>"
          candidatesResults.append(candidateTemplate);

          // Render candidate ballot option
          var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
          candidatesSelect.append(candidateOption);
        });

      }
    }).then(function(hasVoted) {
      loader.hide();
      content.show();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  buy: function() {
    console.log("buying");
    var candidateId = $('#candidatesSelect').val();
    App.contracts.EutMusic.deployed().then(function(instance) {
      return instance.buyAsSatisfyingPrice(0, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  },

  mint: function() {
    var question = $('#questionInput').val();
    console.log("question asked" + question);

    App.contracts.EutMusic.deployed().then(function(instance) {
      return instance.addQuestion(question, { from: App.account });
    }).then(function(result) {
      // Wait for votes to update
      $("#content").hide();
      $("#loader").show();
    }).catch(function(err) {
      console.error(err);
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});