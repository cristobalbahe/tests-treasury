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
  remainingAmount: number;
};

type WrappedSongUserClaimed = {
  [key: string]: {
    [key: string]: {
      amount: number;
      // timestamp: number;
    };
  };
};

type WrappedSongUserTokens = {
  [key: string]: {
    [key: string]: {
      amount: number;
      timestamp: number;
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
          },
        ],
        user2: [
          {
            amount: 2000,
            timestamp: 0,
          },
        ],
        user3: [
          {
            amount: 2000,
            timestamp: 0,
          },
        ],
        user4: [
          {
            amount: 2000,
            timestamp: 0,
          },
        ],
        user5: [
          {
            amount: 2000,
            timestamp: 0,
          },
        ],
      },
    });

  const [wrappedSongUserClaimed, setWrappedSongUserClaimed] =
    useState<WrappedSongUserClaimed>({
      wrappedSong1: {
        user1: {
          amount: 0,
          // timestamp: 0,
        },
        user2: {
          amount: 0,
          // timestamp: 0,
        },
        user3: {
          amount: 0,
          // timestamp: 0,
        },
        user4: {
          amount: 0,
          // timestamp: 0,
        },
        user5: {
          amount: 0,
          // timestamp: 0,
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
              <span onClick={() => {}} style={{ backgroundColor: "lightblue" }}>
                Claimed: {wrappedSongUserClaimed[wrappedSongId][userId].amount}{" "}
                USDC
              </span>{" "}
              {/* - {wrappedSongUserEarnings[wrappedSongId][userId]} USDC USDC */}
              <div>
                <button
                  onClick={() => {
                    let amount = 0;
                    let diff = 0;

                    setWrappedSongUserClaimed((prev) => {
                      //Get distributor timestamps that are greater than user timestamp and add them.
                      diff = distributorTimestamps
                        .filter(
                          (ts) =>
                            ts.timestamp >
                            //EARLIEST TIMESTAMP
                            wrappedSongUserTokens[wrappedSongId][userId][0]
                              .timestamp
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

                      //add this to the amount they had before to have what they own now
                      amount = prev[wrappedSongId][userId].amount + diff;
                      // Update all token timestamps to now

                      // Update the remaining amounts in distributor timestamps
                      setDistributorTimestamps((prevTimestamps) => {
                        const updatedTimestamps = prevTimestamps.map((ts) => {
                          if (
                            ts.timestamp >
                            //EARLIEST TIMESTAMP
                            wrappedSongUserTokens[wrappedSongId][userId][0]
                              .timestamp
                          ) {
                            // Calculate how much this user is claiming from this epoch
                            const userTokens =
                              wrappedSongUserTokens[wrappedSongId][userId];
                            const claimAmount = userTokens.reduce(
                              (sum, token) => {
                                if (token.timestamp <= ts.timestamp) {
                                  return (
                                    sum + (token.amount / 10000) * ts.amount
                                  );
                                }
                                return sum;
                              },
                              0
                            );

                            return {
                              ...ts,
                              remainingAmount: ts.remainingAmount - claimAmount,
                            };
                          }
                          return ts;
                        });

                        // Filter out any timestamps where remainingAmount is 0
                        return updatedTimestamps.filter(
                          (ts) => ts.remainingAmount > 0
                        );
                      });

                      setWrappedSongUserTokens((prev) => ({
                        ...prev,
                        [wrappedSongId]: {
                          ...prev[wrappedSongId],
                          [userId]: [
                            {
                              amount: prev[wrappedSongId][userId].reduce(
                                (sum, token) => sum + token.amount,
                                0
                              ),
                              timestamp: Date.now(),
                              value: 0,
                            },
                          ],
                        },
                      }));

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
                                        wrappedSongUserTokens[wrappedSongId][
                                          userId
                                        ][0].timestamp
                                  )[0]?.timestamp || Date.now(),
                                value: distributorTimestamps
                                  .filter(
                                    (ts) =>
                                      ts.timestamp <= Date.now() &&
                                      ts.timestamp >
                                        //EARLIEST TIMESTAMP
                                        wrappedSongUserTokens[wrappedSongId][
                                          userId
                                        ][0].timestamp
                                  )
                                  .reduce(
                                    (sum, ts) => sum + (1 / 10000) * ts.amount,
                                    0
                                  ),
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
            {
              timestamp: Date.now(),
              amount: 100,
              remainingAmount: 100, // Initialize with full amount
            },
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
            {timestamp.timestamp}: {timestamp.amount} USDC (Remaining:{" "}
            {timestamp.remainingAmount.toFixed(2)} USDC)
          </div>
        ))}
      </div>
    </>
  );
}

export default App;
