(function(){

    //画面初期化
    function setupItems() {
        var grid = $(".timeline").get(0),
            items = [],
            tmpl = _.template( $("#template-item" ).html() ),
            i;

        for (i = 0; i < 10; i++) {
            items.push( document.createElement("article") );
        }

        salvattore.append_elements(grid, items);

        for (i = 0; i < 10; i++) {
            items[i].outerHTML = tmpl({
                "image_url": "http://amenama.on.arena.ne.jp/wordpress/wp-content/uploads/2014/08/cat.png"
            });
        }
    }

    //画面アイテム選択
    function setupItemSelect() {
        $(".select-button").each(function(i, elem) {
            $(elem).click(function() {
                toggle(this);
                getSelectedItem();
            });
            
        });
    }

    //選択したアイテムの属性変更
    function toggle(that) {
        if ($(that).hasClass("selected")) {
            $(that).removeClass("selected");
        } else {
            $(that).addClass("selected");
        }
    }
    
    //選択したアイテムの値を取得する。
    function　getSelectedItem() {
    	$(".item-list").find("selected").each(function(i, element) {
    		var selectedItem = $(element).attr("selected");
    		console.log(selectedItem)
        });   
    }
    
    

    function setupItemsDetail() {
        $(".image").find("img").each(function(i, elem){
            $(elem).click(function() {
                // modalの中身を入れ替え
                $("#item-modal").find(".detail-image").each(function(i, elem2) {
                    var url = $(elem).attr("src");
                    $(elem2).attr("src", url);
                    // modal表示
                    $("#item-modal").modal('show');
                });
            });
        });
    }

    function setupSubmit() {
        $(".btn.btn-primary").each(function(i, e){
            $(e).click(showResult);
        });
    }

    function showResultIcons() {
        var detailContainers = $(".detail"),
            i, n, icon, places,
            conf = [
                [
                    { "placeName": "Shinjyuku-Gyoen" }
                ],
                [
                    { "placeName": "Sky Tree" }
                ],
                [
                    { "placeName": "Ueno Zoo" },
                    { "placeName": "National Museum" },
                    { "placeName": "Takamori Saigo" }
                ],
            ];
        for (i = 0; i < detailContainers.length; i++) {
            places = conf[i];
            for (n = 0; n < places.length; n++) {
                tmplIcon = _.template( $("#template-icon").html() );
                $(detailContainers[i]).append(tmplIcon({
                    "placeName": conf[i][n]["placeName"]
                }));
            }
        }
    }

    function showResult() {
        $("#item-list").addClass("hidden");
        $("#result").removeClass("hidden");

        $("#box-pathway").empty();

        var tmplArrows = _.template( $("#template-arrows").html() ),
            tmplPoint  = _.template( $("#template-point").html() ),
            container  = $("#box-pathway");

        container.append( tmplPoint({ "pointName": "新宿御苑" }) );
        container.append( tmplArrows({ "lineName": "Marunouchi", "requiredMinutes": "5 min" }) );
        container.append( tmplPoint({ "pointName": "押上" }) );
        container.append( tmplArrows({ "lineName": "Ginza", "requiredMinutes": "10 min" }) );
        container.append( tmplPoint({ "pointName": "上野" }) );

        showResultIcons();
    }

    function setupBackButton() {
        $(".back-button").each(function(i, elem){
            $(elem).click(function() {
                $("#result").addClass("hidden");
                $("#item-list").removeClass("hidden");
            });
        });
    }

    setupSubmit();
    setupItems();
    setupItemsDetail();
    setupItemSelect();
    setupBackButton();
})();
