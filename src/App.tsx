import { useState } from "react";
import "./App.css";

// type WrappedSongUserEarnings = {
//   [key: string]: {
//     [key: string]: number;
//   };
// };

type DistributorTimestamp = {
  timestamp: number;
  amount: number;
};

type WrappedSongUserClaimed = {
  [key: string]: {
    [key: string]: {
      amount: number;
      timestamp: number;
    };
  };
};

type WrappedSongUserTokens = {
  [key: string]: {
    [key: string]: {
      amount: number;
      timestamp: number;
      value: number;
      correspondingEarnings: number;
    }[];
  };
};

function App() {
  const [wrappedSongEarnings, setWrappedSongEarnings] = useState<number>(0);
  const [distributorTimestamps, setDistributorTimestamps] = useState<
    DistributorTimestamp[]
  >([]);
  // const [wrappedSongUserEarnings, setWrappedSongUserEarnings] =
  //   useState<WrappedSongUserEarnings>({
  //     wrappedSong1: {
  //       user1: 0,
  //       user2: 0,
  //       user3: 0,
  //       user4: 0,
  //       user5: 0,
  //     },
  //   });
  const [wrappedSongUserTokens, setWrappedSongUserTokens] =
    useState<WrappedSongUserTokens>({
      wrappedSong1: {
        user1: [
          {
            amount: 2000,
            timestamp: 0,
            value: 0,
            correspondingEarnings: 0,
          },
        ],
        user2: [
          {
            amount: 2000,
            timestamp: 0,
            value: 0,
            correspondingEarnings: 0,
          },
        ],
        user3: [
          {
            amount: 2000,
            timestamp: 0,
            value: 0,
            correspondingEarnings: 0,
          },
        ],
        user4: [
          {
            amount: 2000,
            timestamp: 0,
            value: 0,
            correspondingEarnings: 0,
          },
        ],
        user5: [
          {
            amount: 2000,
            timestamp: 0,
            value: 0,
            correspondingEarnings: 0,
          },
        ],
      },
    });

  const [wrappedSongUserClaimed, setWrappedSongUserClaimed] =
    useState<WrappedSongUserClaimed>({
      wrappedSong1: {
        user1: {
          amount: 0,
          timestamp: 0,
        },
        user2: {
          amount: 0,
          timestamp: 0,
        },
        user3: {
          amount: 0,
          timestamp: 0,
        },
        user4: {
          amount: 0,
          timestamp: 0,
        },
        user5: {
          amount: 0,
          timestamp: 0,
        },
      },
    });

  return (
    <>
      {Object.keys(wrappedSongUserTokens).map((wrappedSongId) => (
        <div key={wrappedSongId}>
          <h2>{wrappedSongId}</h2>
          {Object.keys(wrappedSongUserTokens[wrappedSongId]).map((userId) => (
            <div style={{ marginBottom: "20px" }} key={userId}>
              <span
                onClick={() => {
                  console.log(wrappedSongUserTokens[wrappedSongId][userId]);
                }}
                style={{ backgroundColor: "lightgreen" }}
              >
                {userId}:{" "}
                {wrappedSongUserTokens[wrappedSongId][userId].reduce(
                  (sum, token) => sum + token.amount,
                  0
                )}{" "}
                tokens
              </span>{" "}
              -{" "}
              <span
                onClick={() => {
                  console.log(wrappedSongUserClaimed[wrappedSongId][userId]);
                }}
                style={{ backgroundColor: "lightblue" }}
              >
                Claimed: {wrappedSongUserClaimed[wrappedSongId][userId].amount}{" "}
                USDC
              </span>{" "}
              {/* - {wrappedSongUserEarnings[wrappedSongId][userId]} USDC USDC */}
              <div>
                <button
                  onClick={() => {
                    let amount = 0;
                    let diff = 0;

                    setWrappedSongUserTokens((prev) => {
                      const updatedTokens = { ...prev };

                      // Update token values based on distributor timestamps
                      updatedTokens[wrappedSongId][userId] = prev[
                        wrappedSongId
                      ][userId].map((token) => {
                        // Get all distributor timestamps that are after this token's timestamp
                        // and before the last claim timestamp
                        const applicableTimestamps =
                          distributorTimestamps.filter(
                            (ts) =>
                              ts.timestamp > token.timestamp &&
                              ts.timestamp >
                                wrappedSongUserClaimed[wrappedSongId][userId]
                                  .timestamp
                          );

                        // Sum up the amounts from applicable timestamps, dividing by 10000 since each token is 1/10000
                        const additionalValue = applicableTimestamps.reduce(
                          (sum, ts) => sum + ts.amount / 10000,
                          0
                        );
                        const additionalEarnings = applicableTimestamps.reduce(
                          (sum, ts) => sum + ts.amount,
                          0
                        );
                        console.log("additionalValue", additionalValue);
                        console.log("additionalEarnings", additionalEarnings);

                        // Only update value if it's currently 0
                        return {
                          ...token,
                          value:
                            token.value === 0 ? additionalValue : token.value,
                          correspondingEarnings:
                            token.correspondingEarnings === 0
                              ? additionalEarnings
                              : token.correspondingEarnings,
                        };
                        // return {
                        //   ...token,
                        //   value: additionalValue,
                        //   correspondingEarnings: additionalEarnings,
                        // };
                      });

                      return updatedTokens;
                    });

                    setWrappedSongUserClaimed((prev) => {
                      //Get distributor timestamps that are greater than user timestamp and add them.
                      diff = distributorTimestamps
                        .filter(
                          (ts) =>
                            ts.timestamp > prev[wrappedSongId][userId].timestamp
                        )
                        .reduce((sum, ts) => {
                          // Calculate earnings for each token based on timestamp
                          const earnings = wrappedSongUserTokens[wrappedSongId][
                            userId
                          ].reduce((tokenSum, token) => {
                            // If token was created before this distribution timestamp
                            if (token.timestamp <= ts.timestamp) {
                              // Use the token's value property multiplied by amount
                              return (
                                tokenSum + (token.amount / 10000) * ts.amount
                              );
                            }
                            return tokenSum;
                            // return tokenSum + token.value * token.amount;
                          }, 0);

                          return sum + earnings;
                        }, 0);
                      console.log(
                        "earnings",
                        distributorTimestamps
                          .filter(
                            (ts) =>
                              ts.timestamp >
                              prev[wrappedSongId][userId].timestamp
                          )
                          .reduce((sum, ts) => {
                            // Calculate earnings for each token based on timestamp
                            const earnings = wrappedSongUserTokens[
                              wrappedSongId
                            ][userId].reduce((tokenSum, token) => {
                              // If token was created before this distribution timestamp
                              console.log("TOKEN SUM  IS", tokenSum);
                              console.log(
                                "adding multiplied value of ",
                                token.value,
                                "and",
                                token.amount,
                                "which is",
                                token.value * token.amount
                              );

                              if (token.timestamp <= ts.timestamp) {
                                // Use the token's value property multiplied by amount
                                return tokenSum + token.value * token.amount;
                              }
                              return tokenSum;
                            }, 0);

                            return sum + earnings;
                          }, 0)
                      );
                      console.log(
                        "wrappedSongUserTokens",
                        wrappedSongUserTokens[wrappedSongId][userId]
                      );
                      console.log(
                        "DISTRIBUTOR TIMESTAMPS",
                        distributorTimestamps
                      );
                      console.log(
                        "CURRENT WRAPPED SONG TIMESTAMP",
                        prev[wrappedSongId][userId].timestamp
                      );
                      console.log("DIFF", diff);
                      //add this to the amount they had before to have what they own now
                      amount = prev[wrappedSongId][userId].amount + diff;
                      // Update all token timestamps to now

                      return {
                        ...prev,
                        [wrappedSongId]: {
                          ...prev[wrappedSongId],
                          [userId]: {
                            amount: amount,
                            timestamp: Date.now(),
                          },
                        },
                      };
                    });
                    setWrappedSongEarnings((prev) => prev - diff);
                  }}
                >
                  Claim
                </button>
                <div>
                  <div>
                    <input
                      type="text"
                      id={"recipient-id-" + userId}
                      placeholder="Enter user ID"
                      style={{ width: "150px", marginRight: "10px" }}
                    />
                    <input
                      type="number"
                      id={"token-amount-" + userId}
                      placeholder="Enter token amount"
                      style={{ width: "150px", marginRight: "10px" }}
                    />
                    <button
                      onClick={() => {
                        const recipientId =
                          "user" +
                          (
                            document.getElementById(
                              "recipient-id-" + userId
                            ) as HTMLInputElement
                          ).value;
                        const tokenAmount = parseInt(
                          (
                            document.getElementById(
                              "token-amount-" + userId
                            ) as HTMLInputElement
                          ).value
                        );

                        const diff = distributorTimestamps
                          .filter(
                            (ts) =>
                              ts.timestamp >
                              wrappedSongUserClaimed[wrappedSongId][userId]
                                .timestamp
                          )
                          .reduce((sum, ts) => {
                            // Calculate earnings for each token using its stored value
                            const earnings = wrappedSongUserTokens[
                              wrappedSongId
                            ][userId]
                              .filter(
                                (token) => token.timestamp <= ts.timestamp
                              )
                              .reduce((tokenSum, token) => {
                                // Use the token's stored value property
                                return tokenSum + token.amount * token.value;
                              }, 0);

                            return sum + earnings;
                          }, 0);
                        console.log("diff", diff);

                        // return;

                        //Now if the user that wants to send tokend still hasn't claimed their money, we need to calculate the total earnings that would have accumulated until then
                        if (!recipientId) {
                          alert("Please enter a user ID");
                          return;
                        }
                        if (isNaN(tokenAmount)) {
                          alert("Please enter a valid number");
                          return;
                        }
                        if (recipientId === userId) {
                          alert("Cannot send tokens to yourself");
                          return;
                        }

                        setWrappedSongUserTokens((prev) => ({
                          ...prev,
                          [wrappedSongId]: {
                            ...prev[wrappedSongId],
                            [recipientId]: [
                              ...prev[wrappedSongId][recipientId],
                              {
                                amount: tokenAmount,
                                timestamp:
                                  distributorTimestamps.filter(
                                    (ts) =>
                                      ts.timestamp <= Date.now() &&
                                      ts.timestamp >
                                        wrappedSongUserClaimed[wrappedSongId][
                                          userId
                                        ].timestamp
                                  )[0]?.timestamp || Date.now(),
                                value: distributorTimestamps
                                  .filter(
                                    (ts) =>
                                      ts.timestamp <= Date.now() &&
                                      ts.timestamp >
                                        wrappedSongUserClaimed[wrappedSongId][
                                          userId
                                        ].timestamp
                                  )
                                  .reduce(
                                    (sum, ts) => sum + (1 / 10000) * ts.amount,
                                    0
                                  ),
                                correspondingEarnings: distributorTimestamps
                                  .filter((ts) => ts.timestamp <= Date.now())
                                  .reduce((sum, ts) => sum + ts.amount, 0),
                              },
                            ],
                            [userId]: prev[wrappedSongId][userId].map(
                              (token) => ({
                                ...token,
                                amount: token.amount - tokenAmount,
                              })
                            ),
                          },
                        }));
                      }}
                    >
                      Send Tokens
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      ))}

      <div>Total earnings: {wrappedSongEarnings} USDC</div>
      <button
        onClick={() => {
          setDistributorTimestamps((prev) => [
            ...prev,
            { timestamp: Date.now(), amount: 100 },
          ]);
          setWrappedSongEarnings((prev) => prev + 100);
        }}
      >
        Add 100 USDC
      </button>
      <div>
        <h2>Distributor timestamps</h2>
        {distributorTimestamps.map((timestamp) => (
          <div key={timestamp.timestamp}>
            {timestamp.timestamp}: {timestamp.amount} USDC
          </div>
        ))}
      </div>
    </>
  );
}

export default App;
