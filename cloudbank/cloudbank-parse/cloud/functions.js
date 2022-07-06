  Parse.Cloud.define('hello', req => {
    req.log.info(req);
    return 'Hi';
  });
  
  Parse.Cloud.define('asyncFunction', async req => {
    await new Promise(resolve => setTimeout(resolve, 1000));
    req.log.info(req);
    return 'Hi async';
  });
  
  Parse.Cloud.beforeSave('Test', () => {
    throw new Parse.Error(9001, 'Saving test objects is not available.');
  });

  Parse.Cloud.define("averageStars", async (request) => {
    const query = new Parse.Query("Review");
    query.equalTo("movie", request.params.movie);
    const results = await query.find({ useMasterKey: true });
    let sum = 0;
    for (let i = 0; i < results.length; ++i) {
      sum += results[i].get("stars");
    }
    return sum / results.length;
  });

  Parse.Cloud.beforeSave("Review", (request) => {
    console.log(request);
    },{
      fields: {
        stars : {
          required:true,
          options: stars => {
            return stars > 1;
          },
          error: 'Your review must be between one and five stars'
        }
      }
    });
