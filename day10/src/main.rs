use std::fs::read_to_string;

use anyhow::{Result, anyhow, bail};
use good_lp::*;

fn main() -> Result<()> {
    let contents = read_to_string("../inputs/day10/input1.txt")?;
    let result: Vec<u32> = contents
        .split("\n")
        .filter(|line| !line.is_empty())
        .map(|line| -> Result<(Vec<Vec<u32>>, Vec<u32>)> {
            let Some((_, buttons_part)) = line.split_once("] ") else {
                bail!("Invalid input format");
            };
            let Some((buttons_part, joules_part)) = buttons_part.split_once(" {") else {
                bail!("Invalid input format");
            };
            let buttons = buttons_part
                .split(" ")
                .map(|button| {
                    button
                        .trim_matches(['(', ')'])
                        .split(",")
                        .map(|num| num.parse::<u32>().map_err(|_| anyhow!("Invalid number")))
                        .collect::<Result<Vec<u32>, _>>()
                })
                .collect::<Result<Vec<Vec<u32>>, _>>()?;
            let joules = joules_part
                .trim_end_matches("}")
                .split(",")
                .map(|joule| joule.parse::<u32>().map_err(|_| anyhow!("Invalid number")))
                .collect::<Result<Vec<u32>, _>>()?;
            Ok((buttons, joules))
        })
        .map(|data| -> Result<u32> {
            let (buttons, joules) = data?;

            let mut vars = variables!();
            let var_vec: Vec<Variable> = (0..buttons.len())
                .map(|_| vars.add(variable().min(0).integer()))
                .collect();
            let solution: Expression = var_vec.iter().sum();
            let mut problem = vars.minimise(solution).using(default_solver);
            joules.iter().enumerate().for_each(|(idx, joule)| {
                let expr = buttons.iter().enumerate().fold(
                    Expression::from(0.0),
                    |expr, (button_idx, button)| {
                        if button.contains(&(idx as u32)) {
                            expr + var_vec[button_idx]
                        } else {
                            expr
                        }
                    },
                );
                problem.add_constraint(expr.eq(*joule as f64));
            });

            let solution = problem.solve()?;

            Ok(var_vec
                .iter()
                .map(|v| solution.value(*v).round() as u32)
                .sum())
        })
        .collect::<Result<Vec<u32>, _>>()?;

    println!("Result {}", result.iter().sum::<u32>());
    Ok(())
}
