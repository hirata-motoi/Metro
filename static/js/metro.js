(function(){

    window.metro = {};

    function setupItems(categoryId) {

        var grid,
            items = [],
            tmpl = _.template( $("#template-item" ).html() ),
            i, n,
            targetList;

        $(".timeline .item").each(function(i, elem) {
            $(elem).remove();
        });

        grid = $(".timeline").get(0);

        if (categoryId !== undefined && categoryId !== 0) {
            targetList = new Array();
            for (n = 0; n < window.metro.placeList.length; n++) {
                if (window.metro.placeList[n]["category"] == categoryId) {
                    targetList.push(window.metro.placeList[n]);
                }
            }
        } else {
            targetList = window.metro.placeList;
        }

        for (i = 0; i < targetList.length; i++) {
            items.push( document.createElement("article") );
        }

        salvattore.append_elements(grid, items);

        for (i = 0; i < targetList.length; i++) {
            items[i].outerHTML = tmpl({
                "image_url": targetList[i]["image"],
                "name": targetList[i]["name_en"],
                "id": targetList[i]["id"],
                "category": targetList[i]["category"]
            });
        }

        setupSelected();
        setupItemSelect();
        setupItemsDetail();
    }

    function setupSelected() {
        var i, idSelectedMap = {};
        for (i = 0; i < window.metro.placeList.length; i++) {
            idSelectedMap[ window.metro.placeList[i]["id"] ] = window.metro.placeList[i]["selected"];
        }

        $(".item").each(function(i, elem) {
            if (idSelectedMap[ $(elem).attr("data-id") ]) {
                $(elem).addClass("selected");
            } else {
                $(elem).removeClass("selected");
            }
        });
    }

    function setupItemSelect() {
        $(".item .image").each(function(i, elem) {
            $(elem).click(function() {
                toggle(this);
            });
        });
    }

    function toggle(that) {
        var tmplSelectedItem, item = $(that).parents(".item")[0];

        if ($(".item.selected").length >= 7) {
            window.alert("You can select up to 7 items.");
            return;
        }

        if ($(item).hasClass("selected")) {
            $(item).removeClass("selected");

            for (var i = 0; i < window.metro.placeList.length; i++) {
                console.log($(item).attr("data-id"));
                if (window.metro.placeList[i]["id"] === $(item).attr("data-id")) {
                    window.metro.placeList[i]["selected"] = false;
                }
            }

            $(".selected-item-elem[data-id=" + $(item).attr("data-id") + "]").each(function(i, elem) {
                $(elem).remove();
            });
        } else {
            $(item).addClass("selected");
            for (var i = 0; i < window.metro.placeList.length; i++) {
                if (window.metro.placeList[i]["id"] === $(item).attr("data-id")) {
                    window.metro.placeList[i]["selected"] = true;

                    tmplSelectedItem = _.template( $("#template-selected-item").html() );
                    $("#selected-item-list").append(tmplSelectedItem({
                        placeId: window.metro.placeList[i]["id"],
                        iconUrl: "",
                        placeName: window.metro.placeList[i]["name_en"],
                    }));
                }
            }
        }
    }

    function setupItemsDetail() {
        $(".item").find(".detail-button").each(function(i, elem){
            $(elem).click(function() {
                // modalの中身を入れ替え
                $("#item-modal").each(function(i, elem2) {
                    var i, placeData, id = $(elem).parents(".item").attr("data-id");
                    for (i = 0; i < window.metro.placeList.length; i++) {
                        if (window.metro.placeList[i]["id"] == id) {
                            placeData = window.metro.placeList[i];
                            break;
                        }
                    }

                    $(elem2).find(".detail-image").attr("src", placeData["image"]);
                    $(elem2).find(".detail-text").html(placeData["detail"]);
                    $("#myModalLabel").html(placeData["name_en"]);
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
        $("#reset-button").click(function() {
            $(".item.selected").each(function(i, elem) {
                $(elem).removeClass("selected");
            });
            for (var i = 0; i < window.metro.placeList.length; i++) {
                window.metro.placeList[i]["selected"] = false;
            }
        });
    }

    function showResult() {
        var i, startSpotId, placeIds = new Array;

        for (i = 0; i < window.metro.placeList.length; i++) {
            if (window.metro.placeList[i]["selected"]) {
                placeIds.push( window.metro.placeList[i]["id"] );

                if (window.metro.placeList[i]["startSpot"]) {
                    startSpotId = window.metro.placeList[i]["id"]
                }
            }
        }
        if (!startSpotId) {
            window.alert("Please choose start tourist spot");
            return;
        }

        $("#item-list").addClass("hidden");
        $("#result").removeClass("hidden");
        $("#box-pathway").empty();

        $("#loading").show();
        $.ajax({
            url: "/paths",
            dataType: "json",
            data: {p: placeIds, s: startSpotId},
            traditional: true
        }).done(function(data, textStatus, jqXHR) {
            var i, n,
                tmplArrows = _.template( $("#template-arrows").html() ),
                container  = $("#box-pathway"),
                result = data.result,
                stations = result["stations"],
                paths = result["paths"],
                places = result["places"];
                iconUrls = {
                    Ginza: "/static/image/railway/G.jpg",
                    Marunouchi: "/static/image/railway/M.jpg",
                    MarunouchiBranch: "/static/image/railway/M.jpg",
                    Hibiya: "/static/image/railway/H.jpg",
                    Tozai: "/static/image/railway/T.jpg",
                    Chiyoda: "/static/image/railway/C.jpg",
                    Yurakucho: "/static/image/railway/Y.jpg",
                    Fukutoshin: "/static/image/railway/F.jpg",
                    Hanzomon: "/static/image/railway/Z.jpg",
                    Namboku: "/static/image/railway/N.jpg",
                    walk: "/static/image/railway/walk.png",
                };

            for (i = 0; i < stations.length; i++) {
                setupStationPlaceElem(container, stations[i], places);
                if (paths[i]) {

                    var requiredMinutes = (paths[i]["railway"] == "walk") ? "" : "(" + paths[i]["necessary_time"]+" min)";
                    container.append( tmplArrows({
                            "lineName": paths[i]["railway"],
                            "requiredMinutes": requiredMinutes,
                            "iconUrl": iconUrls[ paths[i]["railway"] ]
                    }) );
                }
            }
        }).fail(function() {
        }).complete(function(){
            $("#loading").hide();
        });
    }

    function setupStationPlaceElem(container, station, places) {
        var i,
            tmplIcon = _.template( $("#template-icon").html() ),
            tmplPoint = _.template( $("#template-point" ).html() ),
            stationElem = tmplPoint({"pointName": station["name"]});

        container.append(stationElem);

        if (station["place_index"] !== undefined) {
            if (places[ station["place_index"] ]) {
                for (i = 0; i < places[ station["place_index"] ].length; i++) {

                    var details = $(container).find(".detail");
                    var elem = details[details.length - 1];
                    $(elem).append(tmplIcon({
                        "placeName": places[ station["place_index"] ][i]["name_en"],
                        "iconUrl": places[ station["place_index"] ][i]["image"]
                    }));
                }
            }
        }
    }

    function setupBackButton() {
        $(".back-button").each(function(i, elem){
            $(elem).click(function() {
                $("#result").addClass("hidden");
                $("#item-list").removeClass("hidden");
            });
        });
    }

    function setupCaptureButton() {
        $(".capture-button").each(function(i, elem) {
            $(elem).click(function() {
                // canvasで画像を描画
                html2canvas(document.getElementById("box-pathway"), {
                    onrendered: function(canvas) {
                        // modalの中身にcanvasをセット
                        var container = $($("#capture-modal").find(".modal-body .capture")[0]);
                        container.empty();
                        container.append(canvas);
                        $("#capture-modal").modal('show');
                    }
                });
            });
        });
    }

    // 観光地リストを取得して一覧表示
    // データはwindow.metro.touristSpotsに保持
    function setupTouristSpots() {
        // データ取得
        $.ajax({
            type: "GET",
            url: "/place/list",
        })
        .done(function(data, textStatus, jqXHR) {
            window.metro.placeList = data.result;
            setupItems();
            setupFilterDropDown();
        })
    } 

    function setupEmailSend() {
        $("#email-send").click(function() {
            // validate
            var emailTextbox = $(this).parents(".email-form").find(".email-box")[0];
            var emailConfirmTextbox = $(this).parents(".email-form").find(".email-confirm-box")[0];

            if (!emailTextbox.value || !emailConfirmTextbox.value || emailTextbox.value !== emailConfirmTextbox.value) {
                window.alert("Please confirm your email");
            }

            var canvas = $("canvas")[0];
            var data = canvas.toDataURL();
            data = data.replace('data:image/png;base64,', '');
            var token = getXSRFToken();

            $("#mail-loading").show();
            $("#email-succeeded").hide();
            $.ajax({
                "type": "POST",
                "url": "/image/upload",
                "data": {
                    "XSRF-TOKEN": token,
                    "image": data
                },
                "dataType": "json"
            }).done(function(data, textStatus, jqXHR) {
                sendMail(data.result["filepath"], emailTextbox.value);
            }).fail(function(){
                //window.alert("failed to upload");
                $("#mail-loading").hide();
            }).complete(function() {
            });
        });
    }

    function sendMail(filepath, email) {
        $.ajax({
            "type": "POST",
            "url": "/capture/send",
            "data": {
                "email": email,
                "filepath": filepath
            },
            "dataType": "json"
        }).done(function(data, textStatus, jqXHR) {
            $("#mail-loading").hide();
            $("#email-succeeded").show();
        }).fail(function() {
            window.alert("Failed to send mail");
        });
    }


    function getXSRFToken() {
        var i, matched, token, cookies = document.cookie.split(/\s*;\s*/);
        for (i = 0; i < cookies.length; i++) {
            matched = cookies[i].match(/^XSRF-TOKEN=(.*)$/);
            if (matched) {
                token = matched[1];
            }
        }
        return token
    }

    function setupFilterDropDown() {
        $('.dropdown-menu a').click(function(){
            //反映先の要素名を取得
            var visibleTag = $(this).parents('ul').attr('visibleTag');
            var hiddenTag = $(this).parents('ul').attr('hiddenTag');
            //選択された内容でボタンの表示を変える
            $(visibleTag).html($(this).attr('value'));
            //選択された内容でhidden項目の値を変える
            $(hiddenTag).val($(this).attr('value'));

            // 一覧の表示を絞り込み
            var categoryMap = {
                "All": 0,
                "Garden/Park/Museum": 1,
                "Temple/Shrine": 2,
                "City/Shopping": 3,
                "Tower": 4,
                "Others": 5
            };
            var categoryStr = $(this).attr('value');
            var categoryId = categoryMap[categoryStr];
            setupItems(categoryId);
        });
    }

    function setupGlobalTitle() {
        $("#global-title").click(function() {
            location.href = "/";
        });
    }

    function setupSelectedItemDetail() {
        $(document).on("click", ".selected-item-content", function() {
            var i, id = $(this).parents(".selected-item-elem").attr("data-id"),
                 placeData;
            for (i = 0; i < window.metro.placeList.length; i++) {
               if (window.metro.placeList[i]["id"] == id) {
                   placeData = window.metro.placeList[i];
                   break;
               }
            }

            $("#item-modal").find(".detail-image").attr("src", placeData["image"]);
            $("#item-modal").find(".detail-text").html(placeData["detail"]);
            $("#myModalLabel").html(placeData["name_en"]);
            // modal表示
            $("#item-modal").modal('show');
        });
    }

    function setupStartFromHere() {
        $(document).on("click", ".start-select-button", function() {
            var i, id = $(this).parents(".selected-item-elem").attr("data-id");

            for (i = 0; i < window.metro.placeList.length; i++) {
               if (window.metro.placeList[i]["id"] == id) {
                   window.metro.placeList[i]["startSpot"] = true;
               } else {
                   window.metro.placeList[i]["startSpot"] = false;
               }
            }

            $(".selected-item-elem").each(function(i, elem) {
                $(elem).removeClass("start-spot");
            });
            $(this).parents(".selected-item-elem").addClass("start-spot");
        });
    }

    setupSubmit();
    setupBackButton();
    setupTouristSpots();
    setupCaptureButton();
    setupEmailSend();
    setupGlobalTitle();
    setupSelectedItemDetail();
    setupStartFromHere();
})();
