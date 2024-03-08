# Model-Free Approaches for VIX Products

## Overview
This thesis investigates volatility derivatives, focusing on their role in replication of CBOE's Volatility Index (VIX) and assigning theoretical bounds for VIX futures. It includes a comparative analysis of various pricing and replication methods for variance swaps and variance swap forwards, employing both traditional and novel approaches to model-free replication, such as [Carr and Lee (2007)](https://www.math.uchicago.edu/~rl/OVSwithAppendices.pdf), [Demeterfi et al. (1999)](https://emanuelderman.com/wp-content/uploads/1999/02/gs-volatility_swaps.pdf), [Fukasawa et al. (2011)](https://www-mmds.sigmath.es.osaka-u.ac.jp/structure/activity/vxj/VXJ_DP.pdf) and [CBOE
white paper](https://cdn.cboe.com/api/global/us_indices/governance/Volatility_Index_Methodology_Cboe_Volatility_Index.pdf) are revisited, besides the [at-the-money (ATM) implied volatility (IV)](https://books.google.es/books/about/The_Black_scholes_Formula_is_Nearly_Line.html?id=6z8ptwAACAAJ&redir_esc=y) and the [Rolloos and Arslan (2015)](http://spekulant.com.pl/article/Volatility%20products/Taylor-made%20volatility%20swaps.pdf) methods.

## Tools Used
- **R:** Utilized for data analysis, visualizations and financial data manipulation.
- **LaTeX:** Employed for the documentation and presentation of the thesis.

## Data Collection and Preprocessing
    
This project utilized a range of financial data sources to conduct the analysis, detailed as follows:

### S&P500 Prices and VIX Prices
- **Source:** Extracted using the `tidyquant` package in R, pulling from Yahoo Finance datasets.
- **Period:** January 2011 to December 2020.
- **Details:** Consists of the closing prices of the indexes.

### 3-month Treasury Bills
- **Source:** Daily data scraped from treasury.org.
- **Period:** January 2011 to December 2020.
- **Usage:** Used to determine the risk-free interest rates over the study period.
    
### VIX Futures
- **Source:** Historical data obtained from cboe.com/us/futures.
- **Period:** January 2013 to December 2020.
- **Processing:** Excel files for each period were merged in R to compile the complete dataset.

### Option Data
- **Provider:** OptionMetrics.
- **Period:** January 2011 to December 2020.
- **Details:** Includes bid and ask prices, volume, last trading day, expiration date, option type, implied volatility, and first-order Greeks. Only traditional monthly options were analyzed, excluding weekly, quarterly, and PM settled options (symbols starting with "SPXW", "SPXQ", and "SPXPM") due to computational constraints.

### Data Cleaning Criteria
To work with liquid options to ensure data reliability, options were filtered based on the following criteria:
1. Volume lower than 10 were excluded.
2. Options whose last trading day did not match the data date (or the initial date) were excluded.
3. Entries with NA for implied volatility were removed.
4. Options missing best offer or best bid data were excluded.
5. Options with a spread (difference between best offer and best bid) greater than 2 were eliminated.

### Maturity Dates and Calculation Periods
- Maturity dates were set to the 3rd Friday of each month as we are working with monthly options.
- To mirror VIX price calculations, the period starting 30 days before each maturity was selected.
- Maturities selected ranged from 30 days to 1 year for the approximations of variance swaps, volatility swaps and forwards.

- **Comparative Analysis:** Evaluates the effectiveness of model-free replication strategies for VIX products, detailing the empirical and theoretical framework underpinning each method. 
- **Statistical Analysis:** Application of various statistical tools to measure the performance, deviations, and effectiveness of each replication and pricing method.

## Results and Impact
- The thesis successfully establishes theoretical bounds for VIX futures and variance swaps, providing a granular comparison of replication strategies.
- It uncovers the nuanced differences in pricing methodologies, highlighting their applicability in different market conditions and their implications for risk management.
- The analysis sheds light on the challenges in replicating the VIX, especially during periods of heightened volatility, and proposes solutions through interpolation techniques.

## Challenges and Learnings
- Encountered and overcame significant challenges related to data discrepancies and the application of complex model-free replication methods.
- The research underscored the importance of continuous adaptation and innovation in financial modeling to accurately capture market dynamics.

## How to Run the Code
Instructions for executing the analysis scripts are provided, ensuring reproducibility of results. This includes setup of the R environment, data retrieval, and execution steps.

## Contributions and Collaborations
Acknowledgements to faculty advisors and peers for their invaluable insights and contributions to the research.

## Contact Information
For further discussion about this project or potential collaborations, please reach out to me at [Your Email].

